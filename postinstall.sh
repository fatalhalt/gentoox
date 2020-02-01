#!/bin/bash


# allow Xorg to start and kde to settle
sleep 20


ln -s /usr/share/applications/audacious.desktop ~/Desktop/
ln -s /usr/share/applications/mpv.desktop ~/Desktop/
ln -s /usr/share/applications/steam.desktop ~/Desktop/
flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

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

X_RES=$(xdpyinfo | awk '/dimensions/{print $2}' | tr 'x' ' ' | awk '{print $1}')
Y_RES=$(xdpyinfo | awk '/dimensions/{print $2}' | tr 'x' ' ' | awk '{print $2}')

# install and apply GentooX theme
kpackagetool5 -i "/usr/src/theme/GentooX Breeze Dark Transparent.tar.gz"
lookandfeeltool --apply GentooX

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
kwriteconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group 1 --group General --key positions --type string "4,23,desktop:/mpv.desktop,2,22,desktop:/audacious.desktop,3,22,desktop:/steam.desktop,1,22"
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
kwriteconfig5 --file ~/.config/kdeglobals --group General --key fixed --type string "Hack,9,-1,5,50,0,0,0,0,0,Regular"
kwriteconfig5 --file ~/.config/kdeglobals --group General --key font --type string "Noto Sans,9,-1,5,50,0,0,0,0,0,Regular"
kwriteconfig5 --file ~/.config/kdeglobals --group General --key menuFont --type string "Noto Sans,9,-1,5,50,0,0,0,0,0,Regular"
kwriteconfig5 --file ~/.config/kdeglobals --group General --key smallestReadableFont --type string "Noto Sans,9,-1,5,50,0,0,0,0,0,Regular"
kwriteconfig5 --file ~/.config/kdeglobals --group General --key toolBarFont --type string "Noto Sans,9,-1,5,50,0,0,0,0,0,Regular"
kwriteconfig5 --file ~/.config/kdeglobals --group WM --key activeFont --type string "Noto Sans,9,-1,5,50,0,0,0,0,0,Regular"

kwriteconfig5 --file ~/.config/kglobalshortcutsrc --group kwin --key FlipSwitchAll --type string "none,none,Toggle Flip Switch (All desktops)"
kwriteconfig5 --file ~/.config/kglobalshortcutsrc --group kwin --key lipSwitchCurrent --type string "none,none,Toggle Flip Switch (Current desktop)"

kwriteconfig5 --file ~/.config/kmixrc --group Global --key AutoStart --type bool true

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
#ToDo.....need to finish, see git diff HEAD~1

#qdbus org.kde.KWin /KWin reconfigure
killall plasmashell; kstart5 plasmashell


mkdir -p ~/.config/autostart
ln -s /usr/share/applications/org.kde.latte-dock.desktop ~/.config/autostart/
latte-dock &
kwriteconfig5 --file ~/.config/latte/Default.layout.latte --group Containments --group 1  --group General --key iconSize --type string 48
kwriteconfig5 --file ~/.config/latte/Default.layout.latte --group Containments --group 1  --group General --key panelTransparency --type string 30
pkill latte-dock
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
BorderActivateAll=3
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


# after script runs delete it
sed -i "s/~\/postinstall.sh &//" ~/.xinitrc
rm -- "$0"


media-gfx/gimp heif jpeg2k openexr python vector-icons webp wmf xpm
