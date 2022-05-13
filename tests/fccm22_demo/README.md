## FCCM22 Demo

This block design builds the overlay demonstrated at fccm22. It design uses the RFDC in external loopback with ADC Tile 224 ADCs 0 and 1 connected to DAC Tile 229 DACs 2 and 3, respectivly. Note there is a Balun on the XM500 Balun Card connected to these channels. Data is generate in Python and played out of the DACs and then sampled by the ADCs. The data runs through the OPFB. The capture subsystem along with the bin select block is used to capture the opfb output to PL DDR4 where it can be access and plotted by the PS. 
