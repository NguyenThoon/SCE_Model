//============================================================================
// Name        : discInitOnly_M.cu
// Description : Minimal Disc_M driver that initializes cells and writes
//               one VTK frame, without running any simulation steps.
//============================================================================

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <iostream>
#include <stdexcept>
#include <string>

#include "commonData.h"
#include "CellInitHelper.h"
#include "SimulationDomainGPU.h"

using namespace std;

// The project expects this global config object to exist in the main TU.
GlobalConfigVars globalConfigVars;

#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort = true) {
    if (code != cudaSuccess) {
        fprintf(stderr, "GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
        if (abort) {
            exit(code);
        }
    }
}

// Same style as discMain_M.cu:
//   - default config: ./resources/disc_M.cfg
//   - optional override: -slurm <suffix>, which loads ./resources/disc_<suffix>.cfg
void initializeSlurmConfig(int argc, char* argv[]) {
    ConfigParser parser;
    const std::string configFileNameDefault = "./resources/disc_M.cfg";
    globalConfigVars = parser.parseConfigFile(configFileNameDefault);

    const std::string configFileNameBaseL = "./resources/disc_";
    const std::string configFileNameBaseR = ".cfg";

    if (argc != 1 && argc != 3) {
        std::cout << "ERROR: Incorrect input argument count.\n"
                  << "Expect either no command line argument or three arguments"
                  << std::endl;
        exit(0);
    } else if (argc == 3) {
        if (strcmp(argv[1], "-slurm") != 0) {
            std::cout << "ERROR: one argument received from commandline but it's not recognized.\n"
                      << "Currently, the argument value must be -slurm"
                      << std::endl;
            exit(0);
        } else {
            std::string configFileNameM(argv[2]);
            std::string configFileNameCombined = configFileNameBaseL + configFileNameM + configFileNameBaseR;
            parser.updateConfigFile(globalConfigVars, configFileNameCombined);
        }
    } else {
        int myDeviceID = globalConfigVars.getConfigValue("GPUDeviceNumber").toInt();
        gpuErrchk(cudaSetDevice(myDeviceID));
    }
}

int main(int argc, char* argv[]) {
    try {
        srand(static_cast<unsigned int>(time(NULL)));

        initializeSlurmConfig(argc, argv);

        // Read standard run/output parameters from the config.
        SimulationGlobalParameter mainPara;
        mainPara.initFromConfig();

        std::cout << "Creating initialization helper..." << std::endl;
        CellInitHelper initHelper;

        std::cout << "Creating simulation domain..." << std::endl;
        SimulationDomainGPU simuDomain;

        // Build the exact Disc_M initialization payload used by the main driver.
        std::cout << "Generating Disc_M initialization data..." << std::endl;
        SimulationInitData_V2_M initData = initHelper.initInput_M();

        std::cout << "Initializing GPU domain..." << std::endl;
        simuDomain.initialize_v2_M(initData, mainPara.InitTimeStage);

        // Write one VTK frame immediately after initialization.
        // This gives you a direct visualization of the initial cell layout.
        std::cout << "Writing initial VTK frame..." << std::endl;
        simuDomain.outputVtkFilesWithCri_M(mainPara.animationNameBase, 0, mainPara.aniCri);

        std::cout << "Done. Initial state written to:" << std::endl;
        std::cout << "  " << mainPara.animationNameBase << "00000.vtk" << std::endl;
        std::cout << "No simulation steps were executed." << std::endl;

        return 0;
    } catch (const SceException& e) {
        std::cerr << "SceException: " << e.what() << std::endl;
        return 1;
    } catch (const std::exception& e) {
        std::cerr << "std::exception: " << e.what() << std::endl;
        return 1;
    } catch (...) {
        std::cerr << "Unknown exception caught in discInitOnly_M.cu" << std::endl;
        return 1;
    }
}
