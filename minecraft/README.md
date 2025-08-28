# Overview

`v1.18.2`

The simple minecraft computer comprises of an ALU, a 16 register memory system, and a 7-segment display

# Main Components

## ALU
- The ALU is a component that resolves the issue of logical calculation between two inputs. The ALU in simple terms is a Chained Full Adder with ROM input configuration. The ALU component is able to provide operations such as:
```
- Addition
- Substraction
- Logical Operators (AND, OR, XOR, NAND, NOR, XNOR
```

### ALU Implementation
- The ALU is just a chained full adder, and in minecraft, bitwise operations can be defined easily using redstone, below is an image of XOR gates.

![XOR_gates.png](/minecraft/img/XOR_gates.png)

- The ALU won't use real life chained full adder implementations, instead it will utilize what's known in the communiy as a Carry Cancel Adder or CCA for short.

### Carry Cancel Adder

![CCA_w_ROM.png](/minecraft/img/CCA_w_ROM.png)

- The reason we utilize this instead of implementing rippled chain adders because it is faster and more compact in a minecraft redstone design perspective
- In the image, the black wool extending to the right is the ROM, connecting to parts of the CCA. The ROM determines what operations are the two inputs going to get, effectively making this the ALU

#### The Concept of the CCA
- The reason a chained full adder exists is to account the carry from the previous bit or the Carry In. 
- If a rippled chain adder is to be implemented here, every bit must go through two XORs, two ANDS, and one OR, and the next bit must wait for the other bit's process. 

![Full_adder.png](/minecraft/img/Full_adder.png)

- What the CCA solves is simplifying this problem of addition to only one XOR between two inputs and then one more with the carry, the two inputs and the carry signal
- **The carry signal**, a signal stream of carry-s for the addition problem, it works by starting the signal (or setting `1`s continuouosly) at when two input bit `1`s are met and stopped (or setting `0`s continuously) when two input bit `0`s are met
- Example: two inputs `00000101` and `00000011`. We trace the LSB of both input, `1` and `1` are met. Start a continuous `1` stream for the carry `11111111`. Continue iterating through the bits. Then we reach the MSB, `0` and `0` are met. We now set the carry stream to be continouos `0` resulting in `00001111`.
- After obtaining the carry stream, we must shift it left by 1 bit, or else it won't work as a carry. 
- The resulting process is two operations only, XOR between input `A` and `B`, and then XOR the `result` with the `carry`. 
- The CCA supports up to 8 bit by normal design, but because of its modularity it can be designed up to 32 bits, just by connecting the Carry Out of the CCA as the Carry in of a stacking CCA on top.

## 16 Logical Registers

- Memory in computers are stored using latches, and minecraft has a very simple solution to latches, here is the design:

![Latch.png](/minecraft/img/Latch.png)

- The circled one is the latch, and the blue wool with a stone button is the write signal
- When these latches are stacked vertically, we can create up to 8 bits of storage
- This is a single register of 4 bits: 

![Register.png](/minecraft/img/Register.png)

- Instead of using that system, we can use barrells for latches instead as follows:

![LatchBarrel.png](/minecraft/img/LatchBarrel.png)

- We can then combine to create a very simple 16 register of 4-bits because the design is very modular:

![LatchBarrel.png](/minecraft/img/SimpleRegisters.png)

- We can also place another output (the yellow wool section on the right part of the system) to make it a dual read system, which then yields a system something like this:

![Registers.png](/minecraft/img/Registers.png)

- **Decoders,** the three sets of vertical levers below, is how to determine which registry is the data saved at. The decoder is just binary but translated to unsigned integer.
- Because of the nature of this project, using 4-bits, the system will have `16` or `2**4` registers
- The Green Decoder is the Input Register Decoder, the decoder that determines what register to write
- The Pink Decoders are the Output Register Decoder, the decoder that shows what data is stored within this register
- The Blue set of levers at the top is the input
- The stone button is the write instruction
- The Lever on the orange wool at the bottom is the gate, to give permission of I/O within this memory. If the gate is off, we cannot see the output of the register and we cannot give input to the register.

## 7-Segment Display

![7-segment.png](/minecraft/img/7-segment.png)

- Yes it is build in the floor
- The concept is similar to how we get the register, using a decoder
- The input is a 4-bit integer, we decode that integer into our own set of signals that matches the 7-segment display and the proper number is displayed.
- The decoder is built using a 1-tick observer pulse, which can be a bit inconsistent sometimes due to lag or just the redstone block not getting retracted properly, but overall its very compact

# The CPU Overview

![CPU.png](/minecraft/img/CPU.png)

- The CPU is just the memory register's two outputs directly connected to the ALU, whereas the ALU's output is connected back to the memory register to be written at the user input register.
- The CPU is also able to display the value currently in the user input register, and can be seen on both sides.

### Video Demonstration Link





