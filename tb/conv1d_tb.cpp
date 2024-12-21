// Copyright 2024 Politecnico di Torino.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 2.0 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-2.0. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// File: conv1d.cpp
// Author(s):
//   Luigi Giuffrida
// Date: 08/11/2024
// Description: TB for the OBI CONV1D accelerator.

//Provo a mergiare
#include <iostream>
#include <getopt.h>
#include <random>
#include <time.h>

// Verilator libraries
#include <verilated.h>
#include <verilated_fst_c.h>

// DUT header
#include "Vconv1d_tb_wrapper.h"
#include "conv1d_control_reg.h"

// Testbench components
#include "tb_macros.hh"
#include "tb_components.hh"

// Test data
#include "data.h"

// Defines
// -------
#define FST_FILENAME "logs/waves.fst"
#define END_OF_RESET_TIME 5
#define MAX_SIM_CYCLES 2e6
#define MAX_SIM_TIME (MAX_SIM_CYCLES * 2)
#define WATCHDOG_TIMEOUT 500 // cycles to wait for a program step to complete
#define END_OF_TEST_TIMEOUT 10 // cycles between done assertion and simulation end

// Generate clock and reset
void clkGen(Vconv1d_tb_wrapper *dut);
void rstDut(Vconv1d_tb_wrapper *dut, vluint64_t sim_time);

// Generate OBI transactions
ObiReqTx *genObiWriteReqTx(const vluint32_t addr_offs, const vluint32_t wdata, vluint8_t be);
ObiReqTx *genObiReadReqTx(const vluint32_t addr_offs);
RegReqTx *genRegWriteReqTx(const vluint32_t addr_offs, const vluint32_t wdata, vluint8_t wstrb);
RegReqTx *genRegReadReqTx(const vluint32_t addr_offs);

// Run a number of cycles
void runCycles(unsigned int ncycles, Vconv1d_tb_wrapper *dut, uint8_t gen_waves, VerilatedFstC *trace);

// Global variables
vluint64_t sim_cycles = 0;
TbLogger logger;    // testbench logger

int main(int argc, char *argv[])
{
    // Define command-line options
    const option longopts[] = {
        {"log_level", required_argument, NULL, 'l'},
        {"gen_waves", required_argument, NULL, 'w'},
        {"seed", required_argument, NULL, 's'},
        {NULL, 0, NULL, 0}
    };

    // Process command-line options
    // ----------------------------
    int opt; // current option
    int prg_seed = time(NULL);
    bool gen_waves = true;
    while ((opt = getopt_long(argc, argv, "l:w:", longopts, NULL)) >= 0)
    {
        switch (opt)
        {
        case 'l': // set the log level
            logger.setLogLvl(optarg);
            TB_CONFIG("Log level set to %s", optarg);
            break;
        case 'w': // generate waves
            if (!strcmp(optarg, "true")) {
                gen_waves = 1;
                TB_CONFIG("Waves enabled");
            }
            else {
                gen_waves = 0;
                TB_CONFIG("Waves disabled");
            }
            break;
        case 's': // set the seed
            prg_seed = atoi(optarg);
            TB_CONFIG("Seed set to %d", prg_seed);
            break;
        default:
            TB_ERR("ERROR: unrecognised option %c.\n", opt);
            exit(EXIT_FAILURE);
        }
    }

    // Create Verilator simulation context
    VerilatedContext *cntx = new VerilatedContext;

    // Pass simulation context to the logger
    logger.setSimContext(cntx);

    if (gen_waves)
    {
        Verilated::mkdir("logs");
        cntx->traceEverOn(true);
    }

    // Instantiate DUT
    Vconv1d_tb_wrapper *dut = new Vconv1d_tb_wrapper(cntx);

    // Set the file to store the waveforms in
    VerilatedFstC *trace = NULL;
    if (gen_waves)
    {
        trace = new VerilatedFstC;
        dut->trace(trace, 10);
        trace->open(FST_FILENAME);
    }

    // TB components
    Drv *drv = new Drv(dut);
    Scb *scb = new Scb();
    ReqMonitor *reqMon = new ReqMonitor(dut, scb);
    RspMonitor *rspMon = new RspMonitor(dut, scb);

    // Initialize PRG
    srand(prg_seed);

    // Simulation program
    // ------------------
    // TODO: Define simulation program variables
    ObiReqTx *obi_req = NULL;
    vluint32_t obi_rdata = 0;
    uint32_t obi_data = 0;
    uint32_t obi_addr = 0;
    unsigned int data_size = 0;
    bool obi_accepted = 0;

    RegReqTx *reg_req = NULL;
    vluint32_t reg_rdata = 0;
    bool reg_accepted = 0;

    bool irq_received = 0;

    bool end_of_test = false;
    unsigned int exit_timer = 0;
    unsigned int watchdog = 0;
    unsigned int prev_step_cnt = 0;
    unsigned int step_cnt = 0;

    TB_LOG(LOG_LOW, "Starting simulation...");

    int i = 0;
    int j = 0;
    int k = 0;
    int cnt = 0;
    int be[] = {1, 2, 4, 0};



    while (!cntx->gotFinish() && cntx->time() < MAX_SIM_TIME)
    {
        // Generate clock and reset
        rstDut(dut, cntx->time());
        clkGen(dut);

        // Evaluate simulation step
        dut->eval();

        if (dut->clk_i == 1 && cntx->time() > END_OF_RESET_TIME)
        {
            switch (step_cnt)
            {
            //We read each matrix vertically, we create then a vector containing 4 bytes to be stored in the private memory
            case 0:
                // TODO: implement the simulation program

                if (cnt==0 and i==0){ //first condition to prepare the first row to be sent to the memory
                    for(j=0; j<4; j++) // j counts 4 cycles in order to create a vector of 4 bytes to store in the private memory
                    {
                        //the new byte is always inserted on the right of the vector 
                        //--> left shift of 8 bits to make space for the new data
                        obi_data = obi_data << 8; //row=data that will be inserted in the memory
                        obi_data += F[i]; 
                        i+=5; //go to the next row of the matrix
                    }
                }

                //Memory request
                if (!obi_accepted){
                    obi_req = genObiWriteReqTx(obi_addr, *(&obi_data), 0xf); //we load the memory
                    //printf("Memory_add[%d] <-- Data = %x\n",  obi_addr, obi_data);
                    break;
                }
                // Push expected data to the scoreboard checker queue
                // When a read request is performed, the expected data is compared with the read data
                scb->scheduleObiCheck(obi_data);
                obi_accepted = false; 
                obi_data = 0; //we reset the data vector for next iteration
                obi_addr++; //we increase the memory address pointer
                cnt++; //counter to keep track of how many rows we stored

                //KERNELL MEMORY LOAD
                //The F matrix is a 16x5 matrix. each row is read in 4 j cycles  and in total it requires 
                //5 columns * 4 reading sets for each column = 20
                if (cnt <= 19){ //the first row has already been loaded
                    for(j=0; j<4; j++) // j counts 4 cycles in order to create a vector of 4 bytes to store in the memory
                    {
                        //the new byte is always inserted on the right of the vector 
                        //--> left shift of 8 bits to make space for the new data
                        obi_data = obi_data << 8; //row=data that will be inserted in the memory
                        obi_data += F[i]; 
                        i+=5; //go to the next row of the matrix
                    }

                    //If we reach the end the column, we go to the start of next column
                    if(i>74){
                        i -= 79; //not -75 because we have a final i+=5 
                    }
                }
                else if(cnt == 20){
                    i=0;
                }

                //INPUTS MEMORY LOAD
                //The A matrix portion we want to load int the memori is  16x22 matrix. each row is read in 4 j cycles
                // and in total it requires: 22columns * 4 reading sets for each column = 88
                if (cnt >= 20){ 
                    //We create the single ram row (set0 col0,... set1 col3, ..., set0 col1...)
                    for(j=0; j<4; j++) //j counts 4 cycles in order to create a vector of 4 bytes to store in the memory
                    {
                        obi_data = obi_data << 8; //row=data that will be inserted in the memory
                        obi_data += A[i]; 
                        i+=22;
                    }

                    //If we end the column, we go to the next column
                    if(i>329){
                        i -= 351; //not -329 because we have i+=22 at code line 193 so -329-22=-351
                    }
                }

                
                // Prepare next data element
                if (cnt == 108){
                    step_cnt++;
                }
                break;

            // Wait some cycles
            case 1 ... 3:
                //update the scoreboard with the golden ratio
                for(k=0; k<=17; k++){
                    scb->scheduleObiCheck(R[k]);
                }
                obi_addr = 0;
                data_size = 0;
                step_cnt++;
                break;


            // TODO: add the missing steps (copy filter elements, start computation, etc.)
            case 4:
                reg_req = genRegWriteReqTx(0x0, 0x1, 0xf); //send the start bit to the control register
                printf("The start bit is sent\n");
                printf("\n");
                step_cnt++;
                break;

            case 5:
                reg_req = genRegWriteReqTx(0x0, 0x0, 0xf); //send the start bit is put back to 0
                printf("The start bit is put back to 0\n");
                printf("\n");
                step_cnt++;

            case 6 ... 2500:
                obi_addr = 0;
                data_size = 0;
                step_cnt++;
                break;


            case 2501:
                if (!obi_accepted) {
                    TB_LOG(LOG_HIGH, "Reading data from address '%x'", obi_addr);
                    obi_req = genObiReadReqTx(obi_addr); // this will trigger the check on the written data in step 0
                    break;
                }
                //printf("We read: %x from the address: %d\n", obi_rdata, obi_addr);
                obi_accepted = false;
                obi_addr ++;
                
                if (obi_addr == 126) step_cnt++; // TODO: change exit condition with actual test data size
                break;
            
           
            default:
                // Set simulation exit flag
                end_of_test = true;
                break;
            }


            // Drive DUT inputs
            drv->drive(obi_req, reg_req);
            delete obi_req;
            delete reg_req;
            obi_req = NULL;
            reg_req = NULL;

            // Update input signals
            dut->eval();

            // Monitor DUT signals
            reqMon->monitor();
            rspMon->monitor();
            
            irq_received = rspMon->irq();
            obi_accepted = reqMon->acceptedObi();
            reg_accepted = reqMon->acceptedReg();

            // Get register data (to be used in the test program above)
            if (reg_accepted) {
                reg_rdata = rspMon->getRegData();
            }
            if (rspMon->isDataReadyObi()) obi_rdata = rspMon->getObiData();

            // Trigger scheduled checks
            if (scb->checkData() != 0) end_of_test = true;

            // Check for exit conditions
            if (prev_step_cnt != step_cnt) watchdog = 0;
            else watchdog++;
            if (watchdog > WATCHDOG_TIMEOUT) {
                TB_WARN("Watchdog timeout reached: terminating simulation.");
                scb->notifyError();
                break;
            }
            prev_step_cnt = step_cnt;
            if (end_of_test)
            {
                if (exit_timer++ == END_OF_TEST_TIMEOUT) {
                    TB_LOG(LOG_MEDIUM, "End of simulation reached: terminating.");
                    break;
                }
            }
        } 
        //end clock cycle --------------------------------------------------------------------------------

        // Dump waveforms and advance simulation time
        if (gen_waves) trace->dump(cntx->time());
        if (dut->clk_i == 1) sim_cycles++;
        cntx->timeInc(1);
    }

    // Simulation complete
    dut->final();

    // Print simulation summary
    if (scb->getErrNum() > 0)
    {
        TB_ERR("CHECKS FAILED > errors: %u/%u", scb->getErrNum(), scb->getTxNum());
        if (gen_waves) trace->close();
        exit(EXIT_SUCCESS);
    }
    else if (!scb->isDone())
    {
        TB_ERR("CHECKS PENDING > errors: %u/%u", scb->getErrNum(), scb->getTxNum());
        if (gen_waves) trace->close();
        exit(EXIT_SUCCESS);
    }
    TB_SUCCESS(LOG_LOW, "CHECKS PASSED > errors: %u (checked %u transactions)", scb->getErrNum(), scb->getTxNum());

    // Clean up and exit
    if (gen_waves) trace->close();
    delete dut;
    delete cntx;
    delete obi_req;
    delete reg_req;

    return 0;
}
//end simulation ------------------------------------------------------------------------------------

//MACROS -----------------------------------------------------------------------------------------------
void clkGen(Vconv1d_tb_wrapper *dut)
{
    dut->clk_i ^= 1;
}

void rstDut(Vconv1d_tb_wrapper *dut, vluint64_t sim_time)
{
    dut->rst_ni = 1;
    if (sim_time > 1 && sim_time < END_OF_RESET_TIME)
    {
        dut->rst_ni = 0;
    }
}

void runCycles(unsigned int ncycles, Vconv1d_tb_wrapper *dut, uint8_t gen_waves, VerilatedFstC *trace)
{
    VerilatedContext *cntx = dut->contextp();
    for (unsigned int i = 0; i < (2 * ncycles); i++)
    {
        // Generate clock
        clkGen(dut);

        // Evaluate the DUT
        dut->eval();

        // Save waveforms
        if (gen_waves)
            trace->dump(cntx->time());
        if (dut->clk_i == 1)
            sim_cycles++;
        cntx->timeInc(1);
    }
}

// Issue write OBI transaction
ObiReqTx *genObiWriteReqTx(const vluint32_t addr_offs, const vluint32_t wdata, vluint8_t be)
{
    ObiReqTx *req = new ObiReqTx;

    // OBI write request
    req->obi_req.req = 1;
    req->obi_req.we = 1;
    req->obi_req.be = be;
    req->obi_req.addr = addr_offs;
    req->obi_req.wdata = wdata;

    return req;
}

// Issue read OBI transaction
ObiReqTx *genObiReadReqTx(const vluint32_t addr_offs)
{
    ObiReqTx *req = new ObiReqTx;

    // OBI read request
    req->obi_req.req = 1;
    req->obi_req.we = 0;
    req->obi_req.be = 0xf;
    req->obi_req.addr = addr_offs;
    req->obi_req.wdata = 0;

    return req;
}

// Issue write register interface transaction
RegReqTx *genRegWriteReqTx(const vluint32_t addr_offs, const vluint32_t wdata, vluint8_t wstrb)
{
    RegReqTx *req = new RegReqTx;

    // OBI write request
    req->reg_req.valid = 1;
    req->reg_req.write = 1;
    req->reg_req.wstrb = wstrb;
    req->reg_req.addr = addr_offs;
    req->reg_req.wdata = wdata;

    return req;
}

// Issue read register interface transaction
RegReqTx *genRegReadReqTx(const vluint32_t addr_offs)
{
    RegReqTx *req = new RegReqTx;

    // OBI read request
    req->reg_req.valid = 1;
    req->reg_req.write = 0;
    req->reg_req.wstrb = 0xf;
    req->reg_req.addr = addr_offs;
    req->reg_req.wdata = 0;

    return req;
}
//end macros ------------------------------------------------------------------------------------