# Window Management Specification Sheet

This document defines the comprehensive window management behavior specification based on the original macOS skhd/yabai configuration, inspired by GlazeWM principles, to be implemented in GNOME.

## 🎯 Core Philosophy (GlazeWM Inspired)

**GlazeWM Core Principles Applied:**
- **Keyboard-First Navigation**: All window operations should be achievable without mouse
- **Directional Focus**: hjkl/arrow keys for spatial navigation 
- **Modal Operations**: Special modes for specific tasks (resize, WASD navigation)
- **Visual Feedback**: Clear indication of focused windows and current mode
- **Spatial Awareness**: Focus follows logical window positions
- **Consistent Behavior**: Predictable responses across all contexts

## 🏗️ Architecture Analysis

### Current Implementation Status

#### ✅ **WORKING: Basic Workspace Management**
- **Alt+1-9**: Switch to workspace (✅ matches `cmd+1-9`)
- **Alt+Shift+1-9**: Move window to workspace (✅ matches `cmd+shift+1-9`)
- **Alt+Ctrl+h/l**: Navigate previous/next workspace (✅ matches `cmd+ctrl+h/l`)
- **Workspace Labels**: 9 named workspaces (code, browser, terminal, etc.) ✅
- **Application Auto-Assignment**: Apps move to designated workspaces ✅

#### ❌ **MISSING: Tiling & Keyboard Navigation**
- **Alt+hjkl**: Window focus navigation (configured but no tiling backend)
- **Alt+Shift+hjkl**: Window movement (configured but no tiling backend)
- **BSP Layout**: Binary space partitioning tiling algorithm
- **Focus Indication**: Visual feedback for focused window
- **Spatial Navigation**: Keyboard-driven window traversal

#### ❌ **MISSING: Advanced Features**
- **Modal Resize System**: Alt+r/Alt+p resize modes
- **WASD Navigation Mode**: Alt+w gaming-style navigation
- **Application-Specific Behaviors**: Cursor/Zen browser exclusions
- **Multi-Display Logic**: Fallback behaviors for multi-monitor setups
- **Grid Positioning**: Window placement on 4:4:1:1:2:2 grid system

## 📋 Detailed Behavior Specification

### 1. **Window Focus Navigation (Alt+hjkl)**
```bash
# Original skhd behavior:
cmd - h : yabai -m window --focus west || yabai -m display --focus west
cmd - j : yabai -m window --focus south || yabai -m display --focus south  
cmd - k : yabai -m window --focus north || yabai -m display --focus north
cmd - l : yabai -m window --focus east || yabai -m display --focus east
```

**Required Behavior:**
- **Primary**: Focus window in specified direction (west/south/north/east)
- **Fallback**: If no window exists in direction, focus next display in that direction
- **Visual**: Focused window should have clear visual indication (border, highlight, etc.)
- **Wrapping**: Should NOT wrap around (focus_wraps off)

**GNOME Implementation Needs:**
- Tiling window manager extension (Forge/PaperWM)
- Directional focus commands
- Multi-monitor fallback logic
- Visual focus indicators

### 2. **Window Movement (Alt+Shift+hjkl)**
```bash
# Original skhd behavior:
cmd + shift - h : yabai -m window --warp west || \
    (yabai -m window --display west && yabai -m display --focus west)
```

**Required Behavior:**
- **Primary**: Warp/swap window position within current space
- **Fallback**: If can't warp, move window to adjacent display
- **Focus Follow**: Focus should follow the moved window
- **Layout Preservation**: Should maintain tiling layout integrity

### 3. **Application-Specific Exclusions**
```bash
# Complex skhd behavior:
cmd - j [
    "Cursor" ~                           # Pass through to Cursor
    "Zen" : skhd -k "ctrl - tab"        # Send Ctrl+Tab to Zen
    * : yabai -m window --focus south    # Default: focus south
]
```

**Required Behavior:**
- **Cursor**: Alt+j/k should pass through (IDE navigation)
- **Zen Browser**: Alt+j should send Ctrl+Tab (tab switching)
- **Override Keys**: Alt+Ctrl+j/k force window management even in excluded apps
- **All Other Apps**: Standard window focus behavior

**GNOME Implementation Challenge:**
- Application detection and conditional key handling
- Key passthrough vs. interception logic
- Per-application configuration system

### 4. **Modal Resize System**
```bash
# Original skhd modal system:
:: resize @ : echo "Resize Mode - Use H/L for width, ESC to exit"
alt - r ; resize

resize < h : yabai -m window --resize left:-20:0 || yabai -m window --resize right:-20:0
resize < l : yabai -m window --resize left:20:0 || yabai -m window --resize right:20:0
resize < shift - h : yabai -m window --resize left:-50:0 || yabai -m window --resize right:-50:0
resize < cmd - h : yabai -m window --resize left:-100:0 || yabai -m window --resize right:-100:0
```

**Required Behavior:**
- **Enter Mode**: Alt+r or Alt+p enters resize mode
- **Visual Feedback**: Mode indicator (echo message or visual overlay)
- **Resize Operations**:
  - `h/l`: ±20px width adjustment
  - `Shift+h/l`: ±50px width adjustment  
  - `Cmd+h/l`: ±100px width adjustment
- **Exit Mode**: Escape or common keys (i,j,k,l,space,return,tab) exit back to normal mode
- **Fallback Logic**: Try left edge first, fallback to right edge

### 5. **WASD Navigation Mode**
```bash
# Gaming-style navigation mode:
:: wasd @ : echo "WASD Focus Mode - Use WASD for navigation, ESC to exit"
alt - w ; wasd

wasd < w : skhd -k "up"
wasd < a : yabai -m window --focus west || yabai -m display --focus west || yabai -m space --focus prev
wasd < s : skhd -k "down"  
wasd < d : yabai -m window --focus east || yabai -m display --focus east || yabai -m space --focus next
```

**Required Behavior:**
- **Enter Mode**: Alt+w enters WASD mode
- **Navigation**: w/a/s/d for directional focus
- **Fallback Chain**: window → display → workspace
- **Exit**: Escape or common keys return to normal mode

### 6. **Window Lifecycle Management**
```bash
# Window actions:
alt - f : yabai -m window --toggle float; yabai -m window --grid 4:4:1:1:2:2
cmd + shift - q : yabai -m window --close
alt - tab : yabai -m space --focus recent && yabai -m window --focus first
```

**Required Behavior:**
- **Toggle Float**: Alt+f toggles floating state AND centers window (4:4:1:1:2:2 grid)
- **Close Window**: Alt+Shift+q closes focused window (not application)
- **Recent Space**: Alt+Tab goes to recently used workspace and focuses first window

### 7. **Tiling Configuration (yabai)**
```bash
# Core tiling settings:
yabai -m config \
  mouse_follows_focus on \
  focus_follows_mouse on \
  layout bsp \
  split_ratio 0.50 \
  auto_balance off \
  top_padding 6 \
  bottom_padding 6 \
  left_padding 6 \
  right_padding 6 \
  window_gap 6 \
  active_window_opacity 1.0 \
  normal_window_opacity 0.90 \
  focus_wraps off
```

**Required Configuration:**
- **Layout**: Binary Space Partitioning (BSP)
- **Split Ratio**: 50/50 default splits
- **Auto Balance**: Disabled (manual control preferred)
- **Padding**: 6px on all edges
- **Window Gaps**: 6px between windows
- **Opacity**: Active windows 100%, inactive 90%
- **Focus Wrapping**: Disabled
- **Mouse Behavior**: Focus follows mouse, mouse follows focus

## 🔧 GNOME Implementation Strategy

### Phase 1: Extension Selection & Configuration
**Recommended Extensions:**
1. **Forge** - Primary BSP tiling manager (closest to yabai)
2. **Pop Shell** - Alternative with excellent keyboard navigation
3. **Material Shell** - Advanced tiling with material design

**Configuration Priorities:**
1. BSP layout with 6px gaps
2. Directional focus (Alt+hjkl)
3. Window movement (Alt+Shift+hjkl) 
4. Visual focus indicators
5. Mouse behavior matching yabai

### Phase 2: Modal System Implementation
**Options:**
1. **Extension-based modals** (if supported by chosen tiling extension)
2. **Custom script system** using dbus/gsettings
3. **Shell integration** with custom keybinding handlers

### Phase 3: Application-Specific Behaviors
**Implementation Approaches:**
1. **Per-application keybinding profiles** in dconf
2. **Window rule system** with conditional logic
3. **Custom daemon** for application detection and key routing

### Phase 4: Advanced Features
1. Multi-monitor fallback logic
2. Grid positioning system
3. Workspace-specific layouts
4. Visual feedback enhancements

## 🎮 User Experience Requirements

### Immediate Feedback
- **Visual Focus**: Currently focused window must be clearly distinguishable
- **Mode Indicators**: Current mode (normal/resize/wasd) should be visible
- **Spatial Awareness**: User should understand window relationships

### Consistency
- **Predictable Behavior**: Same key should do same thing across contexts
- **Fallback Logic**: Graceful degradation when primary action fails
- **Error Handling**: Clear feedback when operations can't be performed

### Performance
- **Instant Response**: Key presses should have immediate visible effect
- **Smooth Animations**: Window movements should be visually smooth
- **Resource Efficiency**: Should not impact system performance

## 🔄 Migration Path from Current State

### Short Term (1-2 weeks)
1. **Install and configure Forge extension** for basic tiling
2. **Test current Alt+hjkl bindings** with tiling backend
3. **Verify window movement** Alt+Shift+hjkl functionality
4. **Configure visual focus indicators**

### Medium Term (2-4 weeks)  
1. **Implement modal resize system** (Alt+r mode)
2. **Add application-specific exclusions** (Cursor, Zen)
3. **Configure multi-monitor behaviors**
4. **Implement WASD navigation mode**

### Long Term (1-2 months)
1. **Fine-tune all behaviors** to match skhd exactly
2. **Add missing advanced features** (grid positioning, etc.)
3. **Create comprehensive testing suite**
4. **Document final configuration** for reproducibility

## 📊 Success Metrics

### Functional Requirements
- [ ] All keyboard shortcuts work as specified
- [ ] Tiling behavior matches yabai BSP layout
- [ ] Application exclusions work correctly
- [ ] Modal systems function properly
- [ ] Multi-monitor support operational

### User Experience Requirements  
- [ ] Muscle memory from macOS transfers seamlessly
- [ ] Visual feedback is clear and immediate
- [ ] Performance is equivalent to native yabai
- [ ] Configuration is declarative and reproducible
- [ ] System works across different hardware setups

### Technical Requirements
- [ ] Configuration is version controlled
- [ ] Settings survive GNOME updates
- [ ] Extension dependencies are managed
- [ ] Backup/restore mechanisms exist
- [ ] Multi-system deployment works

## 🔗 Related Technologies & Inspirations

### Direct Inspirations
- **GlazeWM**: Windows tiling with keyboard-first philosophy
- **yabai**: macOS BSP tiling with comprehensive keyboard control
- **i3wm**: Linux tiling pioneer with modal concepts

### GNOME Ecosystem Options
- **Forge**: BSP tiling closest to yabai behavior
- **Pop Shell**: System76's auto-tiling solution
- **Material Shell**: Google Material Design tiling
- **PaperWM**: Scrollable tiling inspired by paper notebooks

### Alternative Approaches
- **Hyprland**: Wayland compositor with advanced tiling
- **Sway**: i3-compatible Wayland compositor
- **Custom window manager**: Built from scratch for exact requirements

---

*This specification serves as the authoritative reference for implementing comprehensive keyboard-driven window management in GNOME that matches the original macOS yabai/skhd workflow while incorporating GlazeWM's keyboard-first philosophy.*
