# Scene Tree As Text

## Introduction
A Godot 4.4 EditorPlugin that generates a text representation of your scene trees, optionally including changes made in the Inspector. It's perfect for documenting scenes, debugging, or getting more effective help from AI models.


## Usage
1. Open your Godot project with the plugin enabled.
2. Access the tool:
   - Go to `Project` > `Tools` in the top menu.
   - Select **"Generate Scene Trees..."**.
3. In the popup window:
   - Add folders to exclude (relative to `res://`, e.g. `addons`).
   - Check the scenes.
   - Optionally enable "Include info about Inspector changes".
4. Click "Generate output.txt" to create the output file in your project’s root directory (`res://output.txt`).


## Installation
1. Place the plugin folder in your project's `res://addons/` directory.
2. Enable it in **`Project Settings > Plugins`**