# This Source Code is subject to the terms of the LICENSE.md file
# located in the root of this project.

class_name ChatOptionButton
extends Button
## a tappable reply bubble for the phone chat sample.


func set_option_text(text: String) -> void:
	self.text = text
