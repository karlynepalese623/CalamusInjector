# 110 - Calamus_Patcher.rb
# Dictionary: Item ID = ITID
# ==============================================================================
#      ++++++++++++++++++++++++ CalamusInjector ++++++++++++++++++++++++++++++
# 1. Press R to open ModMenu.
# 2. Use current ACTION keybind to select
# CalamusInjector v0.1-RLS
# ==============================================================================

# Start.

class ToolGiver_Menu < Window_Command
  def initialize
    commands = [
      "Lightbulb: 1", 
      # "Camera: 8", 
      # "Screwdriver: 9",
      "Empty Battery: 13", 
      "Custom Item ID...",
      "--- Mods ---", # blep :(
      "Coord TP",
      "Map ID Jump",
      "Refresh Map",
      "Dev State Flip",
      "Force Save", 
      "Walk Anywhere",
      "Game Speed FPS",
      "Toggle Diagnostics",
      "Delete Item ID",
      "About" 
    ]
    super(240, commands)
    self.x = (640 - self.width) / 2
    self.y = (480 - self.height) / 2
    self.z = 100000
    self.active = true
  end
end

class Scene_Map
  alias_method :orig_update, :update
  
  def update
    # diagnostics used to always on
    $show_diagnostics ||= false
    if $show_diagnostics
      $debug_coords ||= Debug_Coord_Display.new
      $debug_coords.update
    elsif $debug_coords
      $debug_coords.dispose
      $debug_coords = nil
    end

    if $about_dialogue_step && $about_dialogue_step > 0 && !$game_temp.message_window_showing
      case $about_dialogue_step
      when 1
        $game_temp.message_face = "calamus_shame"
        $game_temp.message_text = "This project took me almost 10 IRL hours to make. Please consider supporting me! Thank you!"
        $about_dialogue_step = 2
      when 2
        $game_temp.message_face = "calamus_heh"
        $game_temp.message_text = "I HEAVILY recommend you backup your save files before using Calamus Injector. It possibly may corrupt your save file. With great power, comes great responsibilties."
        $about_dialogue_step = 3
      when 3
        $game_temp.message_face = "af"
        $game_temp.message_text = "[Legal] OneShot, its characters, story, assets, and code are the property of Future Cat LLC."
        $about_dialogue_step = 4
      when 4
        $game_temp.message_face = "calamus_speak"
        $game_temp.message_text = "[Legal] Calamus Injector is not affiliated, nor endorsed by Future Cat LLC in any way."
        $about_dialogue_step = 5
      when 5
        $game_temp.message_face = "calamus_smile2"
        $game_temp.message_text = "[Legal] This script is provided for purely education, debugging, experimenting, and modding purposes, Pushing the boundaries of OneShot with this."
        $about_dialogue_step = 6
      when 6
        $game_temp.message_face = "calamus_sad"
        $game_temp.message_text = "Use Calamus Injector at your own risk. I'm not responsible for any corrupted save files, or broken flags from the user of modifications within Calamus Injector."
        $about_dialogue_step = 0 
      end
      $game_temp.message_window_showing = true
    end
    
    # i check for cust. ITID inject
    if $pending_item_id && !$game_temp.message_window_showing
      id = $game_variables[99]
      if $data_items[id] != nil
        $game_party.gain_item(id, 1)
      else
        $game_temp.message_face = "calamus_heh"
        $game_temp.message_text = "Err.. Invalid item ID or I couldn't find the ID.. Try looking on the GitHub repository for all the item IDs!"
        $game_temp.message_window_showing = true
      end
      $pending_item_id = false
    end

    # Coord TP
    if $pending_tp_choice && !$game_temp.message_window_showing
      choice = $game_roariables[98]
      $pending_tp_choice = false
      if choice == 1
        $game_temp.num_input_variable_id = 97
        $game_temp.num_input_digits_max = 7
        $game_temp.message_text = "Enter coordinates string:\n(Format: [SignX][X][X][SignY][Y][Y][Y] -> e.g., 10150015 for -15, 15)"
        $game_temp.message_window_showing = true
        $pending_tp_coords = true
      elsif choice == 2
        teleport_to_backup
      else
        $game_temp.message_face = "calamus_sad"
        $game_temp.message_text = "Bad option returned from user. Enter 01 to Teleport or 02 to return."
        $game_temp.message_window_showing = true
      end
    end

    if $pending_tp_coords && !$game_temp.message_window_showing
      coord_string = $game_variables[97]
      $pending_tp_coords = false
      execute_string_teleport(coord_string)
    end

    # handle the map ID tp
    if $pending_map_jump && !$game_temp.message_window_showing
      target_map = $game_variables[96]
      $pending_map_jump = false
      execute_map_jump(target_map)
    end

    # handle dev-switch
    if $pending_state_target && !$game_temp.message_window_showing
      $target_state_id = $game_variables[95]
      $pending_state_target = false
      
      $game_temp.num_input_variable_id = 94
      $game_temp.num_input_digits_max = 2
      $game_temp.message_text = "Target ID: #{$target_state_id}\nPick type:\n01: Toggle switch (ON/OFF)\n02: Set variable value"
      $game_temp.message_window_showing = true
      $pending_state_type = true
    end

    if $pending_state_type && !$game_temp.message_window_showing
      type = $game_variables[94]
      $pending_state_type = false
      
      if type == 1
        current = $game_switches[$target_state_id]
        $game_switches[$target_state_id] = !current
        $game_map.need_refresh = true
        $game_temp.message_face = "calamus_smile2"
        $game_temp.message_text = "Switch #{$target_state_id} flipped from #{current} to #{!current}!"
        $game_temp.message_window_showing = true
      elsif type == 2
        $game_temp.num_input_variable_id = 93
        $game_temp.num_input_digits_max = 4
        $game_temp.message_text = "Enter value to set for Variable #{$target_state_id}:"
        $game_temp.message_window_showing = true
        $pending_variable_val = true
      else
        $game_temp.message_face = "calamus_sad"
        $game_temp.message_text = "Bad option returned from user.."
        $game_temp.message_window_showing = true
      end
    end

    if $pending_variable_val && !$game_temp.message_window_showing
      val = $game_variables[93]
      $pending_variable_val = false
      $game_variables[$target_state_id] = val
      $game_map.need_refresh = true
      $game_temp.message_face = "calamus_smile"
      $game_temp.message_text = "Variable #{$target_state_id} set to #{val}!"
      $game_temp.message_window_showing = true
    end

    # Handle engine fps
    if $pending_fps_val && !$game_temp.message_window_showing
      fps_target = $game_variables[92]
      $pending_fps_val = false
      fps_target = 1 if fps_target < 1
      fps_target = 9999 if fps_target > 9999
      Graphics.frame_rate = fps_target
      $game_temp.message_face = "calamus_smile"
      $game_temp.message_text = "Frames set to #{fps_target} FPS successfully!"
      $game_temp.message_window_showing = true
    end

    # Handle inv deletion thru ITID
    if $pending_del_item && !$game_temp.message_window_showing
      del_id = $game_variables[89]
      $pending_del_item = false
      
      if $game_party.weapon_number(del_id) > 0 || $game_party.armor_number(del_id) > 0 || $game_party.item_number(del_id) > 0 || $data_items[del_id] != nil
        $game_party.lose_item(del_id, 99)
        $game_temp.message_face = "calamus_smile"
        $game_temp.message_text = "Item ID #{del_id} cleared from inventory successfully."
        $game_temp.message_window_showing = true
      else
        $game_temp.message_face = "calamus_speak"
        $game_temp.message_text = "Wait a second, it's not even in your inventory! Or, you listed a wrong Item ID."
        $game_temp.message_window_showing = true
      end
    end
    
    # Handle menu loop./
    if @tool_menu && !@tool_menu.disposed?
      @tool_menu.update
      
      if Input.trigger?(Input::R)
        $game_system.se_play($data_system.cancel_se)
        @tool_menu.dispose
        @tool_menu = nil
        
      elsif Input.trigger?(Input::ACTION)
        if @tool_menu.index == 3
          $game_system.se_play($data_system.buzzer_se)
          return
        end

        $game_system.se_play($data_system.decision_se)
        
        case @tool_menu.index
        when 0..1
          $game_party.gain_item([1, 13][@tool_menu.index], 1)
          @tool_menu.dispose
          @tool_menu = nil
        when 2
          $game_temp.num_input_variable_id = 99
          $game_temp.num_input_digits_max = 2
          $game_temp.message_text = "Enter Item ID please! (01-82)"
          $game_temp.message_window_showing = true
          $pending_item_id = true
          @tool_menu.dispose
          @tool_menu = nil
        when 4
          $game_temp.num_input_variable_id = 98
          $game_temp.num_input_digits_max = 2
          $game_temp.message_text = "Pick an option:\n01: Teleport\n02: Teleport to last coordinate"
          $game_temp.message_window_showing = true
          $pending_tp_choice = true
          @tool_menu.dispose
          @tool_menu = nil
        when 5
          $game_temp.num_input_variable_id = 96
          $game_temp.num_input_digits_max = 3
          $game_temp.message_text = "Enter Map ID to teleport to (001-999):"
          $game_temp.message_window_showing = true
          $pending_map_jump = true
          @tool_menu.dispose
          @tool_menu = nil
        when 6
          force_map_refresh
          @tool_menu.dispose
          @tool_menu = nil
        when 7
          $game_temp.num_input_variable_id = 95
          $game_temp.num_input_digits_max = 3
          $game_temp.message_text = "Enter target switch or Variable ID (001-999):"
          $game_temp.message_window_showing = true
          $pending_state_target = true
          @tool_menu.dispose
          @tool_menu = nil
        when 8
          force_save
          @tool_menu.dispose
          @tool_menu = nil
        when 9
          toggle_noclip
          @tool_menu.dispose
          @tool_menu = nil
        when 10
          $game_temp.num_input_variable_id = 92
          $game_temp.num_input_digits_max = 4
          $game_temp.message_text = "Input set FPS (0001 - 9999):\nDefault FPS is 0060"
          $game_temp.message_window_showing = true
          $pending_fps_val = true
          @tool_menu.dispose
          @tool_menu = nil
        when 11 #diagnostics
          $show_diagnostics = !$show_diagnostics
          @tool_menu.dispose
          @tool_menu = nil
        when 12
          $game_temp.num_input_variable_id = 89
          $game_temp.num_input_digits_max = 2
          $game_temp.message_text = "Enter target Item ID to banish from inventory:"
          $game_temp.message_window_showing = true
          $pending_del_item = true
          @tool_menu.dispose
          @tool_menu = nil
        when 13
          @tool_menu.dispose
          @tool_menu = nil
          $game_temp.message_face = "alula_speak"
          $game_temp.message_text = "Calamus Injector was made by the creator of Alula Editor. [Kip!] (A OneShot save file generator/editor)" 
          $about_dialogue_step = 1
        end
      end
      return
    end
    
    if Input.trigger?(Input::R) && @tool_menu.nil?
      $game_system.se_play($data_system.decision_se)
      @tool_menu = ToolGiver_Menu.new
    end
    
    orig_update
  end
end

# Execution help funcs.
def execute_string_teleport(val)
  str = sprintf("%07d", val)
  sign_x = str[0, 1].to_i
  val_x  = str[1, 2].to_i
  sign_y = str[3, 1].to_i
  val_y  = str[4, 3].to_i
  
  target_x = (sign_x == 1) ? -val_x : val_x
  target_y = (sign_y == 1) ? -val_y : val_y
  
  $last_teleport_x = $game_player.x
  $last_teleport_y = $game_player.y
  
  $game_player.moveto(target_x, target_y)
  
  $game_temp.message_face = "calamus_smile"
  $game_temp.message_text = "Teleported to X: #{target_x}, Y: #{target_y}!\nSaved return point to: #{$last_teleport_x}, #{$last_teleport_y}"
  $game_temp.message_window_showing = true
end

def teleport_to_backup
  if $last_teleport_x && $last_teleport_y
    old_x = $game_player.x
    old_y = $game_player.y
    $game_player.moveto($last_teleport_x, $last_teleport_y)
    $last_teleport_x = old_x
    $last_teleport_y = old_y
    $game_temp.message_face = "calamus_smile2"
    $game_temp.message_text = "TPed back to last coordinate point successfully!"
  else
    $game_temp.message_face = "calamus_heh"
    $game_temp.message_text = "No backup coord found! Teleport somewhere using action 01."
  end
  $game_temp.message_window_showing = true
end

def execute_map_jump(map_id)
  if map_id <= 0
    $game_temp.message_face = "calamus_sad"
    $game_temp.message_text = "Errr.. Map ID must be greater than 0"
    $game_temp.message_window_showing = true
    return
  end
  
  $game_temp.player_transferring = true
  $game_temp.player_new_map_id = map_id
  $game_temp.player_new_x = 0
  $game_temp.player_new_y = 0
  $game_temp.player_new_direction = 2
  
  $game_temp.message_face = "calamus_smile"
  $game_temp.message_text = "Jumping straight to Map ID #{map_id}! Spawning at X:0, Y:0."
  $game_temp.message_window_showing = true
end

def force_map_refresh
  current_map_id = $game_map.map_id
  $game_map.setup(current_map_id)
  $game_player.moveto($game_player.x, $game_player.y)
  
  if $scene.is_a?(Scene_Map)
    $scene.instance_eval do
      if @spriteset
        @spriteset.dispose
        @spriteset = Spriteset_Map.new
      end
    end
  end

  $game_screen.start_flash(Color.new(255, 255, 255, 128), 10)

  $game_temp.message_face = "calamus_smile2"
  $game_temp.message_text = "Refreshed graphics & event states successfully!"
  $game_temp.message_window_showing = true
end

def force_save
  appdata_path = ENV['APPDATA']
  save_file_path = appdata_path ? appdata_path + "/Oneshot/save.dat" : "save.dat" #paths vary btw..

  file = File.open(save_file_path, "wb")
  characters = []
  characters.push([$game_player.character_name, $game_player.character_hue])
  Marshal.dump(characters, file)
  Marshal.dump(Graphics.frame_count, file)
  $game_system.save_count += 1
  $game_system.magic_number = $data_system.magic_number
  Marshal.dump($game_system, file)
  Marshal.dump($game_switches, file)
  Marshal.dump($game_variables, file)
  Marshal.dump($game_self_switches, file)
  Marshal.dump($game_screen, file)
  Marshal.dump($game_actors, file)
  Marshal.dump($game_party, file)
  Marshal.dump($game_troop, file)
  Marshal.dump($game_map, file)
  Marshal.dump($game_player, file)
  file.close
  
  $game_temp.message_face = "calamus_smile2"
  $game_temp.message_text = "Successfully force-saved game to %appdata%/OneShot/save.dat!"
  $game_temp.message_window_showing = true
end

def toggle_noclip
  current_state = $game_player.instance_variable_get(:@through)
  $game_player.instance_variable_set(:@through, !current_state)

  status = $game_player.through ? "enabled" : "disabled"
  $game_temp.message_face = "calamus_speak"
  $game_temp.message_text = "Wait, Niko, You can walk anywhere? [#{status}]"
  $game_temp.message_window_showing = true
end

# Coordinates overlay
class Debug_Coord_Display
  def initialize
    @viewport = Viewport.new(0, 0, 640, 480)
    @viewport.z = 99999
    
    @text = Sprite.new(@viewport)
    @text.bitmap = Bitmap.new(400, 400) 
    @text.x = 10
    @text.y = 10
    
    @idr_text = Sprite.new(@viewport)
    @idr_text.bitmap = Bitmap.new(600, 32)
    @idr_text.x = 10
    @idr_text.y = 480 - 32 - 10
    @idr_text.bitmap.font.size = 16
    @idr_text.bitmap.font.bold = false
    @idr_text.bitmap.draw_text(0, 0, 600, 32, "CalamusPatcher v0.1-RLS | Diagnostics")
  end

  def update
    return if @text.disposed?
    @text.bitmap.clear
    can_dash = $game_player.respond_to?(:dash?) ? $game_player.dash? : "No"
    
    plr_sprite = $game_player.character_name != "" ? $game_player.character_name : "None"
    active_face = ($game_temp.message_face && $game_temp.message_face != "") ? $game_temp.message_face : "None"
    current_bgm = ($game_system.playing_bgm && $game_system.playing_bgm.name != "") ? $game_system.playing_bgm.name : "None"

    lines = [
      "MapID: #{$game_map.map_id}",
      "Pos: #{$game_player.x}, #{$game_player.y}",
      "Direction: #{$game_player.direction} | Moving?: #{$game_player.moving?}",
      "Sprinting?: #{can_dash}",
      "Events@plr: #{$game_map.events.size}",
      "ScreenX: #{$game_player.screen_x} | ScreenY: #{$game_player.screen_y}",
      "Plr sprite: #{plr_sprite}",
      "Dialogue face: #{active_face}",
      "Engine FPS: #{Graphics.frame_rate} FPS",
      "Current bgm: #{current_bgm}",
      "Save count: #{$game_system.save_count}"
    ]
    
    lines.each_with_index do |line, i|
      @text.bitmap.draw_text(0, i * 24, 400, 32, line)
    end
  end
  
  def dispose
    @text.dispose unless @text.disposed?
    @idr_text.dispose unless @idr_text.disposed?
    @viewport.dispose unless @viewport.disposed?
  end
end