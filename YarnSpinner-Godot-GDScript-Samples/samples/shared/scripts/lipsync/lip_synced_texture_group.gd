class_name LipSyncedTextureGroup
extends Resource

enum MouthShape {
    A,
    B,
    C,
    D,
    E,
    F,
    G,
    H,
    TH,
    X
}

@export var textures: Dictionary[MouthShape, Texture2D]

func get_texture(mouth_shape: MouthShape) -> Texture2D:
    if textures.has(mouth_shape):
        return textures.get(mouth_shape)
    else:
        return null;
