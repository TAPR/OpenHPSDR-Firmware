This protocol 2 implementation of Atlas supports 1 or 2 Mercury, a PennyLane, and a Metis board.
Pure Signal is working with Penny providing the 10MHz clock and with 2 Mercury boards Diversity
is supported. Mercury provides 48-384ksps and Metis ethernet is fixed at GigE.

A Penelope can easily be modified to work as a PennyLane. Solder a jumper from the PWM0 output at
P4 pin 6 to the REFIO input to the DAC (U7) by soldering to C23 (not GND side). Then solder a 5.6k
resistor across C48. That will provide the 2V voltage divider, same as PennyLane. Then make sure
to check PennyLane in the SDR client software.

