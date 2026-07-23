class_name LipSyncedTextureGroup
extends Resource

enum MouthShape {
    # // closed mouth: M P B
    A,
    # // slight open mouth with teeth: K S T
    B,
    # // open mouth: most vowels
    C,
    # // wide open mouth: "ah"
    D,
    # // slight rounded mouth: "er"
    E,
    # // puckered lips: "oo"
    F,
    # // labiodental: "ff"
    G,
    # // alveolar: "l"
    H,
    # // dental: "th"
    TH,
    # // mouth closed, silence
    X
}

@export var textures: Dictionary[MouthShape, Texture2D]

func get_texture(mouth_shape: MouthShape) -> Texture2D:
    if textures.has(mouth_shape):
        return textures.get(mouth_shape)
    else:
        return null;
