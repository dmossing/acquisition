MATLAB - LabJackUD .NET examples for Windows
06/24/2014
support@labjack.com


This package contains MATLAB example scripts for using your UD series LabJack
(U3, U6, UE9). They demonstrate LabJack usage using the MATLAB .NET interface
and the LabJackUD .NET assembly LJUDDotNet. Examples were tested with MATLAB 7.9
(R2009b).


Requirements:

1. Windows operating system
2. MATLAB with .NET interface support. Version 7.8 (R2009a) or newer.
3. LabJackUD driver and .NET assembly. Both are provided by the LabJackUD driver
and software installer:

http://labjack.com/support/windows-ud


Getting Started:

First make sure that you have fulfilled the requirements and have extracted the
example scripts somewhere on your computer.

Next, a simple way to get the example scripts running in MATLAB is to click
"Set Path" in the HOME->ENVIRONMENT toolstrip, then click the
"Add with Subfolders" button in the Set Path window and locate the extracted
MATLAB_LJUDDotNET folder. Select the folder and click the "Select Folder"
button. Now back at the "Set Path" window you will see the newly added folders.
Click on the "Save" button and next the "Close" button. In the Command Window
you can now run the example scripts by name, so for example to run the
u3_simple.m script from the MATLAB_LJUDDotNET\Examples\U3 folder type this:

>> u3_simple

Note that the above instructions are from using MATLAB 8.1 (R2013a). "Set Path"
instructions may differ in other MATLAB versions. Also, all example scripts use
the showErrorMessage function in MATLAB_LJUDDotNET\Examples\showErrorMessage.m.


Using the MATLAB .NET interface with the LabJackUD .NET assembly:

To use the LabJackUD .NET assembly in MATLAB use the NET.addAssembly method and
specify 'LJUDDotNet'.

>> ljasm = NET.addAssembly('LJUDDotNet')

That will make the LJUDDotNet's classes accessible in MATLAB. Classes are in
the LabJack.LabJackUD namespace. Information on the UD .NET assembly can be
found in the returned .NET assembly object from the NET.addAssembly call. For
example, to get a list of classes and enumerations type the following:

>> ljasm.Classes
>> ljasm.Enums

To get information on the UD .NET class methods under MATLAB use the
methodsview call. For example:

>> methodsview(LabJack.LabJackUD.LJUD)

For a list of enumeration member names use the enumeration call. For example:

>> enumeration(LabJack.LabJackUD.CHANNEL)

The example scripts will provide more help on MATLAB code and usage.

General UD driver documentation can be found in the User's Guide:

http://labjack.com/support/u3/users-guide/4
http://labjack.com/support/u6/users-guide/4
http://labjack.com/support/ue9/users-guide/4

Example scripts were derived from the .NET C# examples:

http://labjack.com/support/ud/examples/dotnet
