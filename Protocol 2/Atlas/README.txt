This protocol 2 implementation of Atlas supports 1 or 2 Mercurys, a PennyLane, and a Metis board.
Pure Signal is working with Penny providing the 10MHz clock and with 2 Mercury boards Diversity
is supported. Mercury provides 48-384ksps and Metis ethernet is fixed at GigE.

In order for PureSignal to work, the 10MHz clock from PennyLane should be chosen as the source.
Excalibur or Atlas 10MHz also works as the source.

CW handled by the firmware (QSK) is not yet implemented, but CW handled by the application,
Thetis / PiHPSDR, does work.

A Penelope can easily be modified to work as a PennyLane. Solder a jumper from the PWM0 output at
P4 pin 6 to the REFIO input to the DAC (U7) by soldering to C23 (not GND side). Then solder a 5.6k
resistor across C48. That will provide the 2V voltage divider, same as PennyLane. Then make sure
to check PennyLane in the SDR client software.

If using a 2nd Mercury board, put a jumper on GPIO pins 4-5 (header J5) of the 2nd Mercury, no other
jumpers on J5 are necessary. No jumpers on 1st Mercury board J5.

bottom  0 0 X 0 0 0 0 0 0 0 top
        0 0 X 0 0 0 0 0 0 0

The order that I have my boards is (left to right): excalibur | mercury2 | mercury1 | metis | pennylane

This firmware is experimental and is provided for testing, YMMV.
