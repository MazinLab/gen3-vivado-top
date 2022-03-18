# Resonator Test

This test drives the DAC replay output straight to the resonator channelization subsystem including the bin2res block and resonato ddc block followed by a lowpass filter. The bin2res block takes 4096 OPFB output bins and converts them to 2048 user defined resonator channels. This test can be used to verify the functionality of the bin2res IP and fine-tune the ddc system. The capture subsystem is used to caputre the data steam at two points: directly after bin2res (before ddc) and after the ddc + lowpass filter (fine channels).
