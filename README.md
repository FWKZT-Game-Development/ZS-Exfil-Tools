# ZS Exfil Tools

A set of tools for creating exfil areas for FWKZT.

# Commands

	exfil_create [name]
This command creates the exfil and where you give a name for the exfil.


	exfil_origin [name]
This command moves the exfil you have named to the position you are pointing at one of the corners of the cube. (not sure which axis)

	exfil_size [name] [x] [y] [z]
This command is how you size your exfil. A good starting size for the exfil would be about 200 200 150 and go from there.

	exfil_pos [name] [x] [y] [z]
This command just lets you move the exfil to the said position.

	exfil_config [name] [OverrideExfilBool] [ZombieSlayDelay] [ExfilTime] [ExfilDeadline] [UseHatch]
This command is how you set up the exfil's configs. OverrideExfilBool is whether you want to code in a custom exfil escape sequence or not, 1=vehicle and 0=override. ZombieSlayDelay is just how long you want the delay before the zombies are killed and turned into exfil zombies but because the props disappear now when its starts, i'd highly advise using 0. ExfilTime is how long you'd like the exfil's timer to be until they survive, the default being between 5 to 10 seconds. ExfilDeadline is how long it takes for the gas to come in seconds, default being about 120. UseHatch is whether or not you want to use the hatch, 1=hatch and 0=no hatch.

	exfil_save
Saves the exfils onto a file similar to d3 bot

	exfil_delete [name]
This command deletes the exfil specified

##### Video coming soon...
