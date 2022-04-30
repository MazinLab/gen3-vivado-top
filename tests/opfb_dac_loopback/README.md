## OPFB DAC Loopback Test

This block design uses the DCA replay IP to stream Python generated data through the OPFB. The data format is modified between the OPFB and the DAC replay IP so that it matches the format coming from the two ADC AXI Masters. The capture subsystem along with the bin select block is used to capture the opfb output to PL DDR4 where it can be access and plotted by the PS. 
