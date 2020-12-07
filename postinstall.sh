#!/bin/bash


# allow Xorg to start and kde to settle
sleep 15


kdialog --yesno "Would you like to proceed with running postinstall.sh script to apply GentooX theme?
An internet connection is required to pull necessary theme dependency from https://store.kde.org
Plese ensure network connectivity and logout/login for theme to properly apply after script finishes.

All modifications can be reverted by removing dotfiles with rm -rf ~/.* to go back to vanilla KDE theme.

Note: You can run postinstall.sh at later time by executing /usr/src/postinstall.sh script

Continue?"

if [ "$?" = 1 ]; then
  kdialog --sorry "exiting..."
  exit 1
fi;


#ln -s /usr/share/applications/audacious.desktop ~/Desktop/
ln -s /usr/share/applications/mpv.desktop ~/Desktop/
ln -s /usr/share/applications/steam.desktop ~/Desktop/
flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

X_RES=$(xdpyinfo | awk '/dimensions/{print $2}' | tr 'x' ' ' | awk '{print $1}')
Y_RES=$(xdpyinfo | awk '/dimensions/{print $2}' | tr 'x' ' ' | awk '{print $2}')

# install and apply GentooX theme
kpackagetool5 -i "/usr/src/theme/GentooX Breeze Dark Transparent.tar.gz"
lookandfeeltool --apply GentooX --resetLayout

# set wallpaper
dbus-send --session --dest=org.kde.plasmashell --type=method_call /PlasmaShell org.kde.PlasmaShell.evaluateScript 'string:
var Desktops = desktops();
for (i=0;i<Desktops.length;i++) {
        d = Desktops[i];
        d.wallpaperPlugin = "org.kde.image";
        d.currentConfigGroup = Array("Wallpaper",
                                    "org.kde.image",
                                    "General");
        d.writeConfig("Image", "file:///usr/src/theme/1518039301698.png");
}'

# put panel on top and set thickness to 24 pixels
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 3 --key location --type string  3
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 8 --key location --type string  3

HORIZ_RES=$(sed -r -n 's/^\[PlasmaViews\]\[Panel 3\]\[Horizontal(.*)\]/\1/p' ~/.config/plasmashellrc)
kwriteconfig5 --file ~/.config/plasmashellrc --group PlasmaViews --group "Panel 3" --group Defaults --key thickness --type string 24
kwriteconfig5 --file ~/.config/plasmashellrc --group PlasmaViews --group "Panel 3" --group "Horizontal$HORIZ_RES" --key thickness --type string 24

# set icons
sed -i "s/Theme=breeze/Theme=la-capitaine-icon-theme/" ~/.config/kdeglobals
sed -i "s/Theme=breeze/Theme=la-capitaine-icon-theme/" ~/.kde4/share/config/kdeglobals

# set icon positions to top-right edge
#kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 1 --group General --key positions --type string "4,23,desktop:/mpv.desktop,2,22,desktop:/audacious.desktop,3,22,desktop:/steam.desktop,1,22"
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 1 --group General --key sortMode --type string 9999
sed -i "s/sortMode=9999/sortMode=-1/" ~/.config/plasma-org.kde.plasma.desktop-appletsrc

# place Desktop Toolbox to bottom left
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 1 --group General --key ToolBoxButtonState --type string bottomright


echo 'gtk-application-prefer-dark-theme=true
gtk-fallback-icon-theme=breeze
gtk-font-name=Noto Sans Regular 9
gtk-icon-theme-name=la-capitaine-icon-theme
gtk-modules=appmenu-gtk-module
gtk-shell-shows-menubar=1
gtk-theme-name=Breeze-Dark' >> ~/.config/gtk-3.0/settings.ini


kwriteconfig5 --file ~/.config/kdeglobals --group General --key XftHintStyle --type string hintslight
kwriteconfig5 --file ~/.config/kdeglobals --group General --key XftSubPixel --type string rgb
#kwriteconfig5 --file ~/.config/kdeglobals --group General --key fixed --type string "Hack,9,-1,5,50,0,0,0,0,0,Regular"
#kwriteconfig5 --file ~/.config/kdeglobals --group General --key font --type string "Noto Sans,9,-1,5,50,0,0,0,0,0,Regular"
#kwriteconfig5 --file ~/.config/kdeglobals --group General --key menuFont --type string "Noto Sans,9,-1,5,50,0,0,0,0,0,Regular"
#kwriteconfig5 --file ~/.config/kdeglobals --group General --key smallestReadableFont --type string "Noto Sans,9,-1,5,50,0,0,0,0,0,Regular"
#kwriteconfig5 --file ~/.config/kdeglobals --group General --key toolBarFont --type string "Noto Sans,9,-1,5,50,0,0,0,0,0,Regular"
#kwriteconfig5 --file ~/.config/kdeglobals --group WM --key activeFont --type string "Noto Sans,9,-1,5,50,0,0,0,0,0,Regular"
kwriteconfig5 --file ~/.config/kdeglobals --group General --key fixed --type string "Fira Code,9,-1,5,50,0,0,0,0,0"
kwriteconfig5 --file ~/.config/kdeglobals --group General --key font --type string "Fira Sans,9,-1,5,57,0,0,0,0,0,Medium"
kwriteconfig5 --file ~/.config/kdeglobals --group General --key menuFont --type string "Fira Sans,9,-1,5,57,0,0,0,0,0,Medium"
kwriteconfig5 --file ~/.config/kdeglobals --group General --key smallestReadableFont --type string "Fira Sans,9,-1,5,50,0,0,0,0,0"
kwriteconfig5 --file ~/.config/kdeglobals --group General --key toolBarFont --type string "Fira Sans,9,-1,5,57,0,0,0,0,0,Medium"
kwriteconfig5 --file ~/.config/kdeglobals --group WM --key activeFont --type string "Fira Sans,10,-1,5,63,0,0,0,0,0,SemiBold"
kwriteconfig5 --file ~/.config/kdeglobals --group KDE --key LookAndFeelPackage --type string "GentooX"
kwriteconfig5 --file ~/.config/kdeglobals --group KDE --key SingleClick --type bool false

kwriteconfig5 --file ~/.config/kglobalshortcutsrc --group kwin --key FlipSwitchAll --type string "none,none,Toggle Flip Switch (All desktops)"
kwriteconfig5 --file ~/.config/kglobalshortcutsrc --group kwin --key lipSwitchCurrent --type string "none,none,Toggle Flip Switch (Current desktop)"

kwriteconfig5 --file ~/.config/kmixrc --group Global --key AutoStart --type bool false

echo '[Common]
ShadowStrength=89

[Style]
MenuOpacity=70

[Windeco]
TitleAlignment=AlignLeft' > ~/.config/breezerc

echo '[Style]
MenuOpacity=70' > ~/.kde4/share/config/breezerc


kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 3 --group Applets --group 20 --key immutability --type string 1
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 3 --group Applets --group 20 --key plugin --type string "org.kde.plasma.panelspacer"
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 3 --group Applets --group 20 --group Configuration --group General --key length --type string $((X_RES - 413))

kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 3 --group Applets --group 21 --key immutability --type string 1
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 3 --group Applets --group 20 --key plugin --type string "plugin=org.kde.plasma.appmenu"

kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 3 --group Applets --group 6 --group Configuration --key PreloadWeight --delete
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 3 --group Applets --group 6 --key immutability --delete
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 3 --group Applets --group 6 --key plugin --delete

kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 3 --group General --key AppletOrder --type string "4;5;21;20;7;9;10"

kquitapp5 plasmashell; kstart5 plasmashell &
sleep 5



# add systemtray
CONTAINMENT_ID=$(grep -B6 -F 'org.kde.panel' ~/.config/plasma-org.kde.plasma.desktop-appletsrc | grep Containments | tr '[]' ' ' | awk '{print $2}')

kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group $CONTAINMENT_ID --group Applets --group 32 --key immutability --type string 1
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group $CONTAINMENT_ID --group Applets --group 32 --key plugin --type string "org.kde.plasma.systemtray"
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group $CONTAINMENT_ID --group Applets --group 32 --group Configuration --key PreloadWeight --type string 47
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group $CONTAINMENT_ID --group Applets --group 32 --group Configuration --key SystrayContainmentId --type string 33

#kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group $CONTAINMENT_ID --group General --key AppletOrder --type string "12;13;14;15;32;16;17;18"
LINE_NUM=$(grep -n -A1 -F "[Containments][$CONTAINMENT_ID][General]" ~/.config/plasma-org.kde.plasma.desktop-appletsrc | tail -n1 | cut -d- -f1)
APPLET_ORDER=$(grep -A1 -F "[Containments][$CONTAINMENT_ID][General]" ~/.config/plasma-org.kde.plasma.desktop-appletsrc | tail -n1)
NEW_APPLET_ORDER="$(echo $APPLET_ORDER | awk -F';' -v v=32 '{print $1,$2,$3,$4,v,$5,$6,$7}' | tr ' ' ';')"
NEW_APPLET_ORDER_STRING="${NEW_APPLET_ORDER#*=}"
#sed -i "${LINE_NUM}c$NEW_APPLET_ORDER" ~/.config/plasma-org.kde.plasma.desktop-appletsrc
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group $CONTAINMENT_ID --group General --key AppletOrder --type string "$NEW_APPLET_ORDER_STRING"

kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --key activityId --type string ""
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --key formfactor --type string 2
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --key immutability --type string 1
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --key lastScreen --type string 0
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --key location --type string 3
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --key plugin --type string "org.kde.plasma.private.systemtray"
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --key wallpaperplugin --type string "org.kde.image"

kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 35 --key immutability --type string 1
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 35 --key plugin --type string "org.kde.plasma.clipboard"
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 35 --group Configuration --key PreloadWeight --type string 42
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 36 --key immutability --type string 1
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 36 --key plugin --type string "org.kde.plasma.devicenotifier"
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 36 --group Configuration --key PreloadWeight --type string 42
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 37 --key immutability --type string 1
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 37 --key plugin --type string "org.kde.kdeconnect"
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 37 --group Configuration --key PreloadWeight --type string 42
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 38 --key immutability --type string 1
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 38 --key plugin --type string "org.kde.plasma.keyboardindicator"
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 38 --group Configuration --key PreloadWeight --type string 42
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 39 --key immutability --type string 1
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 39 --key plugin --type string "org.kde.plasma.nightcolorcontrol"
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 39 --group Configuration --key PreloadWeight --type string 42
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 40 --key immutability --type string 1
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 40 --key plugin --type string "org.kde.plasma.notifications"
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 40 --group Configuration --key PreloadWeight --type string 42
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 41 --key immutability --type string 1
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 41 --key plugin --type string "org.kde.plasma.printmanager"
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 41 --group Configuration --key PreloadWeight --type string 42
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 42 --key immutability --type string 1
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 42 --key plugin --type string "org.kde.plasma.vault"
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 42 --group Configuration --key PreloadWeight --type string 42
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 43 --key immutability --type string 1
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 43 --key plugin --type string "org.kde.plasma.battery"
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 43 --group Configuration --key PreloadWeight --type string 42
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 44 --key immutability --type string 1
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 44 --key plugin --type string "org.kde.ktp-contactlist"
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 44 --group Configuration --key PreloadWeight --type string 42
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 45 --key immutability --type string 1
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 45 --key plugin --type string "org.kde.plasma.mediacontroller"
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Applets --group 45 --group Configuration --key PreloadWeight --type string 42

kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group Configuration --key PreloadWeight --type string 42

kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group General --key extraItems --type string "org.kde.kdeconnect,org.kde.ktp-contactlist,org.kde.plasma.battery,org.kde.plasma.bluetooth,org.kde.plasma.clipboard,org.kde.plasma.devicenotifier,org.kde.plasma.keyboardindicator,org.kde.plasma.mediacontroller,org.kde.plasma.networkmanagement,org.kde.plasma.nightcolorcontrol,org.kde.plasma.notifications,org.kde.plasma.printmanager,org.kde.plasma.vault,KMix"
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group General --key hiddenItems --type string "KMix"
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 33 --group General --key knownItems --type string "org.kde.kdeconnect,org.kde.ktp-contactlist,org.kde.plasma.battery,org.kde.plasma.bluetooth,org.kde.plasma.clipboard,org.kde.plasma.devicenotifier,org.kde.plasma.keyboardindicator,org.kde.plasma.mediacontroller,org.kde.plasma.networkmanagement,org.kde.plasma.nightcolorcontrol,org.kde.plasma.notifications,org.kde.plasma.printmanager,org.kde.plasma.vault,org.kde.plasma.volume"



mkdir -p ~/.config/autostart
ln -s /usr/share/applications/org.kde.latte-dock.desktop ~/.config/autostart/
latte-dock &
sleep 5
kill -s 15 $(pidof latte-dock)
kwriteconfig5 --file ~/.config/latte/My\ Layout.layout.latte --group Containments --group 1  --group General --key iconSize --type string 48
kwriteconfig5 --file ~/.config/latte/My\ Layout.layout.latte --group Containments --group 1  --group General --key panelTransparency --type string 30
kwriteconfig5 --file ~/.config/latte/My\ Layout.layout.latte --group Containments --group 1  --group Applets --group 2 --group Configuration --group General --key launchers59 --type string "applications:firefox.desktop,applications:org.kde.dolphin.desktop,applications:org.kde.konsole.desktop"
latte-dock &


# gtk2
echo 'gtk-primary-button-warps-slider=0
gtk-cursor-theme-name="breeze_cursors"
gtk-font-name="Noto Sans Regular 9"
gtk-theme-name="Breeze-Dark"
gtk-icon-theme-name="la-capitaine-icon-theme"
gtk-fallback-icon-theme="breeze"
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-menu-images=1
gtk-button-images=1
gtk-modules=appmenu-gtk-module' > ~/.gtkrc-2.0

# kwinrc
echo '[$Version]
update_info=kwin.upd:replace-scalein-with-scale,kwin.upd:port-minimizeanimation-effect-to-js,kwin.upd:port-scale-effect-to-js,kwin.upd:port-dimscreen-effect-to-js,kwin.upd:auto-bordersize

[Compositing]
OpenGLIsUnsafe=false

[Desktops]
Id_1=b6fcd628-81dd-40e4-b879-d260a6a2506e
Number=1
Rows=1

[Effect-CoverSwitch]
TabBox=false
TabBoxAlternative=false

[Effect-Cube]
BorderActivate=9
BorderActivateCylinder=9
BorderActivateSphere=9

[Effect-DesktopGrid]
BorderActivate=9

[Effect-FlipSwitch]
TabBox=true
TabBoxAlternative=false

[Effect-PresentWindows]
BorderActivate=9
BorderActivateAll=5
BorderActivateClass=9

[Effect-kwin4_effect_translucency]
Menus=90

[ElectricBorders]
Bottom=None
BottomLeft=None
BottomRight=None
Left=None
Right=None
Top=None
TopLeft=None
TopRight=None

[Plugins]
flipswitchEnabled=true
highlightwindowEnabled=true
kwin4_effect_squashEnabled=false
magiclampEnabled=true

[TabBox]
ActivitiesMode=1
ApplicationsMode=0
BorderActivate=9
BorderAlternativeActivate=9
DesktopLayout=org.kde.breeze.desktop
DesktopListLayout=org.kde.breeze.desktop
DesktopMode=1
HighlightWindows=true
LayoutName=thumbnails
MinimizedMode=0
MultiScreenMode=0
ShowDesktopMode=0
ShowTabBox=true
SwitchingMode=0

[TabBoxAlternative]
ActivitiesMode=1
ApplicationsMode=0
DesktopMode=1
HighlightWindows=true
LayoutName=org.kde.breeze.desktop
MinimizedMode=0
MultiScreenMode=0
ShowDesktopMode=0
ShowTabBox=true
SwitchingMode=0

[Windows]
ElectricBorderCooldown=350
ElectricBorderCornerRatio=0.25
ElectricBorderDelay=150
ElectricBorderMaximize=true
ElectricBorderTiling=true
ElectricBorders=0

[org.kde.kdecoration2]
BorderSize=Normal
BorderSizeAuto=true
ButtonsOnLeft=XAIH
ButtonsOnRight=S
CloseOnDoubleClickOnMenu=false
ShowToolTips=true
library=org.kde.sierrabreeze
theme=Sierra Breeze' > ~/.config/kwinrc
qdbus org.kde.KWin /KWin reconfigure




# konsole, breeze color scheme with blur and 15% transparency
mkdir -p ~/.local/share/konsole

echo '[Background]
Color=35,38,39

[BackgroundFaint]
Color=49,54,59

[BackgroundIntense]
Color=0,0,0

[Color0]
Color=35,38,39

[Color0Faint]
Color=49,54,59

[Color0Intense]
Color=127,140,141

[Color1]
Color=237,21,21

[Color1Faint]
Color=120,50,40

[Color1Intense]
Color=192,57,43

[Color2]
Color=17,209,22

[Color2Faint]
Color=23,162,98

[Color2Intense]
Color=28,220,154

[Color3]
Color=246,116,0

[Color3Faint]
Color=182,86,25

[Color3Intense]
Color=253,188,75

[Color4]
Color=29,153,243

[Color4Faint]
Color=27,102,143

[Color4Intense]
Color=61,174,233

[Color5]
Color=155,89,182

[Color5Faint]
Color=97,74,115

[Color5Intense]
Color=142,68,173

[Color6]
Color=26,188,156

[Color6Faint]
Color=24,108,96

[Color6Intense]
Color=22,160,133

[Color7]
Color=252,252,252

[Color7Faint]
Color=99,104,109

[Color7Intense]
Color=255,255,255

[Foreground]
Color=252,252,252

[ForegroundFaint]
Color=239,240,241

[ForegroundIntense]
Color=255,255,255

[General]
Blur=true
ColorRandomization=false
Description=Breeze
Opacity=0.85
Wallpaper=' > ~/.local/share/konsole/Breeze.colorscheme


# systemtray, 2nd attempt to apply the widget
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group $CONTAINMENT_ID --group General --key AppletOrder --type string "$NEW_APPLET_ORDER_STRING"


# create KIO aware mpv .desktop shortcut
mkdir -p ~/.local/share/applications
cp /usr/share/applications/mpv.desktop ~/.local/share/applications/mpv-kio.desktop
sed -i -r "s/^Name=(.*)$/Name=mpv Media Player \(KIO cat from smb\)/g" ~/.local/share/applications/mpv-kio.desktop
sed -i -r "s/^Exec=(.*)$/Exec=mpv-kio.sh/g" ~/.local/share/applications/mpv-kio.desktop


# after script runs delete it
sed -i "s/~\/postinstall.sh &//" ~/.xinitrc
rm -- "$0"

qdbus org.kde.ksmserver /KSMServer logout 1 0 0
