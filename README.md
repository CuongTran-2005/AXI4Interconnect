# AXI4 Interconnect
A Verilog implementation of an AXI4 interconnect supporting multiple masters and multiple slaves with QoS-aware arbitration, transaction ID handling, and outstanding transacitons.

## Features

- Multiple master and slave interfaces.
- Configurable number of master and slave interfaces.
- Interrupt controller 
- Weighted round-robin arbitration based on QOS signals
- AXI4 ordering constraint compliant
- Simple address mapping mechanism
- Multiple outstanding transaction

## Description

### Architecture
![overall_arch_figure](/assets/overall_arch.png)

Datapath includes multiple master and slave interface for connecting to master and slave components. The number of master and slave interfaces can be configured using `SLV_AMT` and `MST_AMT` parameter in the top module `axi4_interconnect.v`. Skid buffer eliminates the combinational path on the handshake signal, improves timing end ensures no data loss when the receiver suddenly stops receiving data. Each master and slave will have a dispatch to control and distribute traffic to the expected destination. Dispatches are controller by Controller and Arbiter modules. Each path between a master and interconnect is controlled by a **Controller**. Each path between a slave and interconnect is controlled by an **Arbiter**. 

#### Master-side dispatch block diagram
![master_dispatch](/assets/master_dispatch.drawio.png)

#### Slave-side dispatch block diagram
![slave_dispatch](/assets/dispatch_slave.drawio.png)

#### Controller block diagram
![controller_block_diagram](/assets/controller_block_diagram.png)

#### Arbiter block diagram
![arbiter_block_diagram](/assets/arbiter_block_diagram.png)

### Address mapping mechanism
All slaves are assigned an equal address space. Therefore, the interconnect uses the upper bits to determine which slave to route to for each transaction. These upper bits are called slave ID. The width of slave ID is equal to `log2(SLV_AMT)`. The interfaces are flattended out into sigle port and the LSB correspond to interface having slave ID 0.

#### Example: 4 masters and 4 slaves
In a system with `MST_AMT = 4` and `SLV_AMT = 4`, the slave ID width is 2 bits. The interconnect uses the upper 2 address bits to select one of the four slaves. For example, with a 32-bit address space:

- Slave 0: `0x00000000` to `0x3FFFFFFF`
- Slave 1: `0x40000000` to `0x7FFFFFFF`
- Slave 2: `0x80000000` to `0xBFFFFFFF`
- Slave 3: `0xC0000000` to `0xFFFFFFFF`

If a master issues an access to address `0xA1234567`, the upper two bits are `0b10`, so the transaction is routed to Slave 2. The same address decoding rule applies regardless of which one of the four masters initiates the transaction. In this case, the master ID is used for tracking and ordering, while the slave ID is used to choose the destination slave.

### Weighted round-robin arbitration
Both Controller and Arbiter use weighted round-robin algorithm to arbitrate data transfer. QOS signal is considerd as weight associated with transaction. In Master side, arbitration algoritim is applied to R and B channel conducted by `Data channel controller` modules. In Slave side, arbitration algorithm is applied to AW and AR channel. The AXI4 specification requires that data beats on the W channel follow the exact transaction order in which they are issued on the AW channel. Therefore, no arbitration mechanism is applied to the W channel.


#### Example: arbitration on the R channel
Assume the system has 1 master and 2 slave (Slave 0 and Slave 1). Master issues two read transaction to Slave 0 and Slave 1 sequentially with the QOS signals are 0 and 1 respectively. The two slaves then return data to master on R channel. The timeline is shown in the following table.

| Time (clk) | Master 2 <-> IC | IC <-> Slave 0 | IC <-> Slave 1 |
| :--- | :--- | :--- | :--- |
|  0 | AR (ID=0) | | |
|  3 | AR (ID=1) | AR (ID=0) | |
|  4 | | R (0xaaaa0001) | |
|  5 | | R (0xaaaa0002) | |
|  6 | | R (0xaaaa0003) | AR (ID=1) |
|  7 | | R (0xaaaa0004) | R (0xbbbb0001) |
|  8 | | R (0xaaaa0005) | R (0xbbbb0002) |
|  9 | R (0xaaaa0001) | R (0xaaaa0006) | R (0xbbbb0003) |
|  10 | R (0xaaaa0002) | R (0xaaaa0007) | R (0xbbbb0004) |
|  11 | R (0xbbbb0001) | **R (0xaaaa0008)** | R (0xbbbb0005) |
|  12 | R (0xbbbb0002) | | R (0xbbbb0006) |
|  13 | R (0xaaaa0003) | | R (0xbbbb0007) |
|  14 | R (0xbbbb0003) | | **R (0xbbbb0008)** |
|  15 | R (0xbbbb0004) | | |
|  16 | R (0xaaaa0004) | | |
|  17 | R (0xbbbb0005) | | |
|  18 | R (0xbbbb0006) | | |
|  19 | R (0xaaaa0005) | | |
|  20 | R (0xbbbb0007) | | |
|  21 | **R (0xbbbb0008)** | | |
|  22 | R (0xaaaa0006) | | |
|  23 | R (0xaaaa0007) | | |
|  24 | **R (0xaaaa0008)** | | |

We see that although Master  sends a read transaction to Slave 0
first and then sends a read transaction to Slave 1. But when the data is received, the
transaction of Slave 1 ends first. Looking at the timeline, we can see that Interconnect
allocated more transmission channels to traffic coming from Slave 1 than coming from
Slave 0 during the time that both slaves requested the transmission channel.

### Data channel controller
#### Block diagram
![data_channel_controller](/assets/data_channel_controller.png)

The data channel controller (DCC) is a submodule located in the controller. DCC is a
system consisting of multiple FIFOs, each corresponding to a Transaction ID used to
store information about transactions with specific IDs. The data stored in these FIFOs
is the QoS value of the transaction and the Slave ID associated with that transaction.
FIFOs act as a look-up table to keep track of transactions being processed. An FSM is
used to resolve and allocate the transmission channel to the slaves using the Weigth
Round-robin algorithm to input the QoS information of the transaction stored in the
FIFO. The larger the QoS transaction, the more cycles the transmission channel will be
allocated in a whole FSM allocation cycle.

#### State diagram
![dcc_state_diagram](/assets/dcc_state_diagram.png)

The main FSM has four states.
- **IDLE**: no request from any slave or after system reset, main FSM is put into IDLE state.
- **ARBITRATION**: when one of the slaves request transmission channel, main FSM will move to ARBITRATION state. In this state, controller set round-robin module's `enable` signal to start performing round-robin arbitration algoritm.
- **ALLOCATION**: this state indicates that the transmission channel is allocated to a specific slave and the master is ready to receive data. In this state, the arbitration process is still being caring out.
- **STALL**: this state indicates that the transmission channel is allocated to a specific slave but the master is not ready to receive data. Then the controller will hold the transmission line and wait until the master is ready to accept data again.

![dcc_controller_block](/assets/dcc_controller_block.png)

![dcc_controller_comb_circuit](/assets/dcc_controller_comb_circuit.png)

### Interrupt Controller
#### Block diagram
![Interrupt_controller](/assets/interrupt_controller.png)

The Interrupt Controller is designed in the style of a Level-Triggered Interrupt
Controller, supporting:

- Allows each source to be interrupted (Interrupt Masking) turned on/off.
- Set Priority.
- Save the Pending Register.
- Select the Priority Arbiter.
- Control the sending of interrupts to Master via FSM.
- Serve only one interrupt at a time.

#### State diagram
![int_ctr_state_diagram](/assets/interrupt_controller_state_diagram.png)

#### Interrupt controller operation logic

Interrupt Controller is designed according to the model: Interrupt Detection → Save
Status → Interrupt Filter → Select Priority Interrupt → Serve Control → Clear Interrupt
State

- **Step 1**. Receive a disconnect request. Slaves send interrupt requests through irq_0,
irq_1, irq_2, irq_3 signals. Each signal corresponds to an independent interrupt source.

- **Step 2**. Save the Pending status. Each interrupt source is attached to a separate Pending
register. irq_0 -> Pending Register -> irq_pending_0. The Pending register will pick up
the state of the interrupt and update the status of the interrupt after each cycle. This
helps the interrupt signal from the slave sent to the interrupt controller to be more stable.

- **Step 3**. Interrupt Masking Filtering. Not every interrupt source needs to be dealt with at
all times. So each interrupt source is associated with an Enable signal (from the master). This process is done using the AND ports. Although pending = 1, if it is not
enabled, this interrupt signal will not be sent to the arbiter block. Thanks to this
mechanism, the Master can actively turn on or off each interrupt source during system
operation.

- **Step 4**. Priority Arbitration. After removing the disabled interrupt sources, the
remaining signals are fed to the Interrupt Arbiter block. This block receives two groups of signals:
    - Interrupt requests have been Enabled (irq_masked)
    - Priority Table (irq_priority) controlled by the master

- **Step 5**. Control the servicing process. The arbitration result is included in the FSM
block. The FSM has the following tasks:
    - Send a break request to the Master;
    - Keep the interrupt request stable throughout the Master reception process;
    - Wait for a confirmation signal from the Master (irq_ack);
    - Decide when to delete pending status

- **Step 6**. Master confirmed. After receiving a interrupt request, the Master sends a irq_ack
signal to inform you that the interrupt request has been received. At this time, FSM will
turn off the interrupt signal sent to the master so that the master does not mistake another
interrupt. FSM will wait for the slave's interrupt to end (at this time, the master has
solved the interrupt, so the slave lowers the interrupt signal). Once finished, the interrupt
controller returns to the IDLE state and starts a new interrupt (if any).

## Usage

Configure parameters in the top module file `axi4_interconnect.v` according to system requirements.

### Parameter
The top-level module `axi4_interconnect.v` uses the following configurable parameters:

| Parameter | Meaning | Use |
| :--- | :--- | :--- |
| `MST_AMT` | Number of master interfaces | Sets how many masters can connect to the interconnect. |
| `SLV_AMT` | Number of slave interfaces | Sets how many slaves can be addressed by the interconnect. |
| `DATA_WIDTH` | Width of data buses | Defines the bit width of `WDATA`, `RDATA`, and related data signals. |
| `ADDR_WIDTH` | Width of address buses | Defines the address bit width used for address decoding and slave selection. |
| `TRANS_MST_ID_W` | Width of transaction master ID | Sets the bit width for AXI transaction IDs on the master side. |
| `TRANS_BURST_W` | Width of burst type field | Defines the number of bits used for burst-related information. |
| `TRANS_DATA_LEN_W` | Width of transfer length field | Sets the bit width for the AXI transfer length field. |
| `TRANS_DATA_SIZE_W` | Width of data size field | Defines the bit width for the AXI transfer size field. |
| `TRANS_WR_RESP_W` | Width of write response field | Sets the bit width for write response encoding. |
| `TRANS_QOS_W` | Width of QoS field | Defines the number of bits used for QoS-based arbitration. |
| `MST_ID_W` | Width of master ID | Derived from `MST_AMT`; used to identify which master issued a transaction. |
| `SLV_ID_W` | Width of slave ID | Derived from `SLV_AMT`; used to identify which slave is selected by address decoding. |
| `OUTSTANDING_AMT` | Maximum outstanding transactions | Limits how many transactions can be in flight at the same time. |
| `FIFO_DEPTH` | Depth of internal FIFOs | Controls buffering capacity for transaction and data flow through the interconnect. |

### Ports

The top-level module exposes a standard AXI-like interface on both the master side and slave side. The ports are organized as follows:

#### Global ports

| Port | Direction | Description |
| :--- | :--- | :--- |
| `ACLK_i` | Input | System clock used by the interconnect and internal FIFOs. |
| `ARESETn_i` | Input | Active-low reset signal that initializes the interconnect. |

#### Master-side ports

| Port | Direction | Description |
| :--- | :--- | :--- |
| `m_AWID_i` | Input | Transaction ID for each master write address channel. |
| `m_AWADDR_i` | Input | Write address from each master. |
| `m_AWLEN_i` | Input | Burst length for each master write transaction. |
| `m_AWSIZE_i` | Input | Transfer size for each master write transaction. |
| `m_AWBURST_i` | Input | Burst type for each master write transaction. |
| `m_AWQOS_i` | Input | QoS value for each master write transaction. |
| `m_AWVALID_i` | Input | Valid signal for the write address channel from each master. |
| `m_AWREADY_o` | Output | Ready signal for the write address channel to each master. |
| `m_WDATA_i` | Input | Write data from each master. |
| `m_WLAST_i` | Input | Indicates the last write beat from each master. |
| `m_WVALID_i` | Input | Valid signal for the write data channel from each master. |
| `m_WREADY_o` | Output | Ready signal for the write data channel to each master. |
| `m_BID_o` | Output | Write response ID returned to each master. |
| `m_BRESP_o` | Output | Write response status returned to each master. |
| `m_BVALID_o` | Output | Valid signal for the write response channel to each master. |
| `m_BREADY_i` | Input | Ready signal from each master for write responses. |
| `m_ARID_i` | Input | Transaction ID for each master read address channel. |
| `m_ARADDR_i` | Input | Read address from each master. |
| `m_ARLEN_i` | Input | Burst length for each master read transaction. |
| `m_ARSIZE_i` | Input | Transfer size for each master read transaction. |
| `m_ARBURST_i` | Input | Burst type for each master read transaction. |
| `m_ARQOS_i` | Input | QoS value for each master read transaction. |
| `m_ARVALID_i` | Input | Valid signal for the read address channel from each master. |
| `m_ARREADY_o` | Output | Ready signal for the read address channel to each master. |
| `m_RID_o` | Output | Read data ID returned to each master. |
| `m_RDATA_o` | Output | Read data returned to each master. |
| `m_RRESP_o` | Output | Read response status returned to each master. |
| `m_RLAST_o` | Output | Indicates the last read beat returned to each master. |
| `m_RVALID_o` | Output | Valid signal for the read data channel to each master. |
| `m_RREADY_i` | Input | Ready signal from each master for read data. |

#### Slave-side ports

| Port | Direction | Description |
| :--- | :--- | :--- |
| `s_AWID_o` | Output | Write address transaction ID forwarded to each slave. |
| `s_AWADDR_o` | Output | Write address forwarded to each slave. |
| `s_AWLEN_o` | Output | Burst length forwarded to each slave on write transactions. |
| `s_AWSIZE_o` | Output | Transfer size forwarded to each slave on write transactions. |
| `s_AWBURST_o` | Output | Burst type forwarded to each slave on write transactions. |
| `s_AWQOS_o` | Output | QoS value forwarded to each slave on write transactions. |
| `s_AWVALID_o` | Output | Valid signal for the write address channel to each slave. |
| `s_AWREADY_i` | Input | Ready signal from each slave for the write address channel. |
| `s_WDATA_o` | Output | Write data forwarded to each slave. |
| `s_WLAST_o` | Output | Indicates the last write beat forwarded to each slave. |
| `s_WVALID_o` | Output | Valid signal for the write data channel to each slave. |
| `s_WREADY_i` | Input | Ready signal from each slave for the write data channel. |
| `s_BID_i` | Input | Write response ID returned from each slave. |
| `s_BRESP_i` | Input | Write response status returned from each slave. |
| `s_BVALID_i` | Input | Valid signal for the write response channel from each slave. |
| `s_BREADY_o` | Output | Ready signal for the write response channel to each slave. |
| `s_ARID_o` | Output | Read address transaction ID forwarded to each slave. |
| `s_ARADDR_o` | Output | Read address forwarded to each slave. |
| `s_ARLEN_o` | Output | Burst length forwarded to each slave on read transactions. |
| `s_ARSIZE_o` | Output | Transfer size forwarded to each slave on read transactions. |
| `s_ARBURST_o` | Output | Burst type forwarded to each slave on read transactions. |
| `s_ARQOS_o` | Output | QoS value forwarded to each slave on read transactions. |
| `s_ARVALID_o` | Output | Valid signal for the read address channel to each slave. |
| `s_ARREADY_i` | Input | Ready signal from each slave for the read address channel. |
| `s_RID_i` | Input | Read data ID returned from each slave. |
| `s_RDATA_i` | Input | Read data returned from each slave. |
| `s_RRESP_i` | Input | Read response status returned from each slave. |
| `s_RLAST_i` | Input | Indicates the last read beat returned from each slave. |
| `s_RVALID_i` | Input | Valid signal for the read data channel from each slave. |
| `s_RREADY_o` | Output | Ready signal for the read data channel to each slave. |

## Verification

### Running the testbench with the .do script

#### prerequisite
ModelSim or QuestaSim installed on system.

#### Running the automation script

The project includes a ModelSim/Questa simulation script at [testbench/run_sim.do](testbench/run_sim.do). To run the testbench:

1. Open a terminal in the project root.
2. In the tool prompt, run:

   ```bash
   vsim -c -do testbench/run_sim.do
   ```

3. The script will:
   - compile all RTL files from [rtl](rtl),
   - compile the testbench files from [testbench](testbench),
   - create or reuse the `work` library,
   - load the top-level testbench [testbench/tb_axi4_interconnect.sv](testbench/tb_axi4_interconnect.sv),
   - run the full simulation until completion.

4. After the simulation finishes, you can inspect the waveform and logged output in the simulator window.

    ```bash
    vsim -view testbench/vsim.wlf
    ```

If you are using a GUI environment, you can also open the waveform viewer after the simulation starts to observe the AXI transactions and arbitration behavior.

### Testcases in the testbench

The testbench [testbench/tb_axi4_interconnect.sv](testbench/tb_axi4_interconnect.sv) contains six main test cases:

1. Testcase 1: one write and one read transaction
   - Writes a value to memory through the interconnect and then performs a read back.
   - This checks the basic write-read path and simple address routing.

2. Testcase 2: two write transactions at the same time
   - Starts write transactions from two different masters concurrently.
   - This verifies contention handling on the write path and the interconnect’s ability to arbitrate multiple writers.

3. Testcase 3: two read transactions at the same time
   - Starts two read transactions from two masters concurrently.
   - This exercises the read-response path and checks that responses are routed back correctly.

4. Testcase 4: two write transactions with different QoS values
   - Issues two write bursts from different masters with different QoS levels.
   - This validates that QoS-aware arbitration influences the scheduling of write traffic.

5. Testcase 5: two read transactions with different QoS values
   - Issues two read transactions with different QoS values and preloads slave memory with response data.
   - This verifies weighted round-robin behavior and the ordering of read-data return on the R channel.

6. Testcase 6: four read transactions to four different slaves from two masters
   - Launches multiple read requests targeting different slave addresses from two masters at the same time.
   - This tests address decoding, multi-slave routing, and the behavior of the interconnect under heavier concurrency.



