# DoctorDark

![preview](preview.png) 

# Information:

- Designed for 10.10+   
- DoctorDark is a SIMBL plugin that tries to bring dark mode to every application window on macOS   
- Author: [w0lfschild](https://github.com/w0lfschild)

# Note:

- Some applications may look bad or crash
- Applications with custom windows will likely not be effected
- You can blacklist an app using the GUI or terminal:
    - `defaults write org.w0lf.drdark $(osascript -e 'id of app "Application Name"') 0`

# Installation:

1. Download [mySIMBL](https://github.com/w0lfschild/app_updates/raw/master/mySIMBL/mySIMBL_0.2.5.zip)
2. Download [DoctorDark](https://github.com/w0lfschild/DoctorDark/raw/master/build/DoctorDark.bundle.zip)
3. Unzip downloads
4. Open `DoctorDark.bundle` with `mySIMBL.app`
5. Restart any application to have DoctorDark plugin loaded
	
### License:
Pretty much the BSD license, just don't repackage it and call it your own please!    
Also if you do make some changes, feel free to make a pull request and help make things more awesome!
