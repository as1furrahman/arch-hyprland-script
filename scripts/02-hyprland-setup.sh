#!/bin/bash
#===============================================================================
# 02-hyprland-setup.sh - Hyprland & Wayland Stack Setup
# Installs Hyprland and all required Wayland components
#===============================================================================

log_step "Starting Hyprland setup..."

#===============================================================================
# PACKAGE LISTS
#===============================================================================

# Hyprland core packages
PACKAGES_HYPRLAND=(
    # Compositor
    "hyprland"
    
    # Hyprland ecosystem
    "hypridle"
    "hyprlock"
    "hyprpaper"
    "hyprpicker"
    "hyprshot"
    "hyprsunset"
    "swww"
    
    # XDG Portals
    "xdg-desktop-portal-hyprland"
    "xdg-desktop-portal-gtk"
    
    # Qt Wayland support
    "qt5-wayland"
    "qt6-wayland"
    
    # Authentication
    "polkit-kde-agent"
    
    # Clipboard
    "wl-clipboard"
    "cliphist"
    
    # Utilities
    "brightnessctl"
    "playerctl"
    "grim"
    "slurp"
    "swappy"
    
    # Notifications
    "libnotify"
    "mako"
    
    # File manager
    "thunar"
    "thunar-volman"
    "gvfs"
    "tumbler"
    "ffmpegthumbnailer"
    
    # Terminal
    "foot"
    "kitty"
    
    # App launcher (fallback)
    "wofi"
    
    # Image viewer
    "imv"
    
    # GTK theming
    "gtk3"
    "gtk4"
    "gsettings-desktop-schemas"
    
    # Cursor theme
    "breeze"
    
    # Icons
    "papirus-icon-theme"
)

# AUR packages for Hyprland
PACKAGES_HYPRLAND_AUR=(
    "grimblast-git"
)

#===============================================================================
# INSTALL HYPRLAND PACKAGES
#===============================================================================
install_hyprland() {
    log_step "Installing Hyprland and Wayland stack..."
    
    # Install from official repos
    log_info "Installing Hyprland packages..."
    sudo pacman -S --needed --noconfirm "${PACKAGES_HYPRLAND[@]}"
    
    # Install AUR packages
    log_info "Installing AUR packages..."
    $AUR_HELPER -S --needed --noconfirm "${PACKAGES_HYPRLAND_AUR[@]}" || true
    
    log_success "Hyprland packages installed"
}

#===============================================================================
# CREATE HYPRLAND CONFIG DIRECTORY
#===============================================================================
setup_hyprland_config() {
    log_step "Setting up Hyprland configuration..."
    
    local hypr_config_dir="$HOME/.config/hypr"
    
    # Create config directory
    mkdir -p "$hypr_config_dir"
    
    # Check if config exists or needs repair
    if [ ! -f "$hypr_config_dir/hyprland.conf" ] || grep -q "workspace_swipe_fingers" "$hypr_config_dir/hyprland.conf" 2>/dev/null; then
        
        if [ -f "$hypr_config_dir/hyprland.conf" ]; then
            log_warning "Found broken/deprecated configuration (workspace_swipe_fingers)."
            log_info "Backing up old config to hyprland.conf.bak..."
            mv "$hypr_config_dir/hyprland.conf" "$hypr_config_dir/hyprland.conf.bak"
        fi

        log_info "Creating fresh Hyprland configuration..."
        
        # Always use our known-good template (system sample may have deprecated options)
        cat > "$hypr_config_dir/hyprland.conf" << 'EOF'
#===============================================================================
# HYPRLAND CONFIGURATION
# For ASUS Zenbook S 13 OLED (UM5302TA)
#===============================================================================

#-------------------------------------------------------------------------------
# MONITOR CONFIGURATION
#-------------------------------------------------------------------------------
# UM5302TA: 13.3" 2880x1800 OLED @ 60Hz
monitor = , preferred, auto, 1.5

#-------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
#-------------------------------------------------------------------------------
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORMTHEME,qt5ct
env = GDK_BACKEND,wayland,x11
env = QT_QPA_PLATFORM,wayland;xcb
env = SDL_VIDEODRIVER,wayland
env = CLUTTER_BACKEND,wayland
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland

#-------------------------------------------------------------------------------
# AUTOSTART
#-------------------------------------------------------------------------------
exec-once = udiskie &
exec-once = /usr/lib/polkit-kde-authentication-agent-1
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
exec-once = hypridle
exec-once = mako

#-------------------------------------------------------------------------------
# INPUT
#-------------------------------------------------------------------------------
input {
    kb_layout = us
    follow_mouse = 1
    
    touchpad {
        natural_scroll = true
        tap-to-click = true
        disable_while_typing = true
    }
    
    sensitivity = 0
}

#-------------------------------------------------------------------------------
# GENERAL
#-------------------------------------------------------------------------------
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(89b4faee) rgba(cba6f7ee) 45deg
    col.inactive_border = rgba(313244aa)
    layout = dwindle
}

#-------------------------------------------------------------------------------
# DECORATION
#-------------------------------------------------------------------------------
decoration {
    rounding = 10
    
    blur {
        enabled = true
        size = 5
        passes = 3
        new_optimizations = true
    }
    
    shadow {
        enabled = true
        range = 15
        render_power = 3
        color = rgba(1a1a1aee)
    }
}

#-------------------------------------------------------------------------------
# ANIMATIONS
#-------------------------------------------------------------------------------
animations {
    enabled = true
    
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

#-------------------------------------------------------------------------------
# LAYOUT
#-------------------------------------------------------------------------------
dwindle {
    pseudotile = true
    preserve_split = true
}

master {
    new_status = master
}

gestures {
    workspace_swipe = true
}

misc {
    force_default_wallpaper = 0
    disable_hyprland_logo = true
}

#-------------------------------------------------------------------------------
# KEYBINDINGS
#-------------------------------------------------------------------------------
$mainMod = SUPER

# Core
bind = $mainMod, Return, exec, foot
bind = $mainMod, Q, killactive,
bind = $mainMod SHIFT, Q, exit,
bind = $mainMod, E, exec, thunar
bind = $mainMod, V, togglefloating,
bind = $mainMod, D, exec, wofi --show drun
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,
bind = $mainMod, F, fullscreen,

# Focus
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Workspaces
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Move to workspace
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

# Scroll through workspaces
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Move/resize windows
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow

# Screenshot
bind = , Print, exec, grimblast --notify copy area
bind = SHIFT, Print, exec, grimblast --notify copy output

#-------------------------------------------------------------------------------
# FUNCTION KEYS (Will be overridden by Ax-Shell)
#-------------------------------------------------------------------------------
# Volume
bindle = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindle = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindle = , XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+

# Brightness
bindle = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
bindle = , XF86MonBrightnessUp, exec, brightnessctl set +5%

# Media
bind = , XF86AudioPlay, exec, playerctl play-pause
bind = , XF86AudioNext, exec, playerctl next
bind = , XF86AudioPrev, exec, playerctl previous

#-------------------------------------------------------------------------------
# WINDOW RULES
#-------------------------------------------------------------------------------
windowrulev2 = float, class:^(pavucontrol)$
windowrulev2 = float, class:^(blueman-manager)$
windowrulev2 = float, class:^(nm-connection-editor)$
windowrulev2 = float, title:^(Picture-in-Picture)$
windowrulev2 = float, class:^(imv)$
EOF
        
        log_success "Hyprland configuration generated"
    else
        log_info "Hyprland config exists and passed checks."
    fi
}

#===============================================================================
# CONFIGURE HYPRIDLE (OLED-OPTIMIZED)
#===============================================================================
setup_hypridle() {
    log_step "Configuring hypridle for OLED..."
    
    local hypr_config_dir="$HOME/.config/hypr"
    
    cat > "$hypr_config_dir/hypridle.conf" << 'EOF'
#===============================================================================
# HYPRIDLE - OLED OPTIMIZED
# Aggressive timeouts to protect OLED panel
#===============================================================================

general {
    lock_cmd = pidof hyprlock || hyprlock
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
}

# Dim screen after 2 minutes
listener {
    timeout = 120
    on-timeout = brightnessctl -s set 10%
    on-resume = brightnessctl -r
}

# Lock screen after 5 minutes
listener {
    timeout = 300
    on-timeout = loginctl lock-session
}

# Turn off display after 10 minutes
listener {
    timeout = 600
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}

# Suspend after 30 minutes
listener {
    timeout = 1800
    on-timeout = systemctl suspend
}
EOF
    
    log_success "hypridle configured for OLED"
}

#===============================================================================
# CONFIGURE HYPRLOCK
#===============================================================================
setup_hyprlock() {
    log_step "Configuring hyprlock..."
    
    local hypr_config_dir="$HOME/.config/hypr"
    
    cat > "$hypr_config_dir/hyprlock.conf" << 'EOF'
#===============================================================================
# HYPRLOCK CONFIGURATION
#===============================================================================

background {
    monitor =
    path = screenshot
    blur_passes = 3
    blur_size = 8
    noise = 0.0117
    contrast = 0.8916
    brightness = 0.8172
    vibrancy = 0.1696
    vibrancy_darkness = 0.0
}

input-field {
    monitor =
    size = 200, 50
    outline_thickness = 3
    dots_size = 0.33
    dots_spacing = 0.15
    dots_center = true
    dots_rounding = -1
    outer_color = rgb(151515)
    inner_color = rgb(200, 200, 200)
    font_color = rgb(10, 10, 10)
    fade_on_empty = true
    fade_timeout = 1000
    placeholder_text = <i>Password...</i>
    hide_input = false
    rounding = -1
    check_color = rgb(204, 136, 34)
    fail_color = rgb(204, 34, 34)
    fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i>
    fail_timeout = 2000
    fail_transition = 300
    capslock_color = -1
    numlock_color = -1
    bothlock_color = -1
    invert_numlock = false
    swap_font_color = false
    position = 0, -20
    halign = center
    valign = center
}

label {
    monitor =
    text = $TIME
    text_align = center
    color = rgba(200, 200, 200, 1.0)
    font_size = 55
    font_family = JetBrainsMono Nerd Font
    rotate = 0
    position = 0, 80
    halign = center
    valign = center
}
EOF
    
    log_success "hyprlock configured"
}

#===============================================================================
# RUN HYPRLAND SETUP
#===============================================================================
run_hyprland_setup() {
    echo ""
    log_info "═══════════════════════════════════════════════════════════════"
    log_info "                    HYPRLAND SETUP                             "
    log_info "═══════════════════════════════════════════════════════════════"
    echo ""
    
    install_hyprland
    setup_hyprland_config
    setup_hypridle
    setup_hyprlock
    
    echo ""
    log_success "Hyprland setup completed!"
    log_info "You can now start Hyprland by typing 'Hyprland' after logging in."
    echo ""
}

# Run if executed directly or sourced
run_hyprland_setup
