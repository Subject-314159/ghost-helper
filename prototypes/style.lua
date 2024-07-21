local styles = data.raw["gui-style"].default

styles["main_pane"] = {
    type = "scroll_pane_style",
    horizontally_stretchable = "on",
    maximal_height = 600,
    width = 350,
    padding = 0,
    border = {},
    graphical_set = {
        base = {
            position = {17, 0},
            corner_size = 8,
            draw_type = "outer"
        }
    }
}

styles["main_frame"] = {
    type = "vertical_flow_style",
    -- parent = "inside_shallow_frame_with_padding",
    horizontally_stretchable = "on",
    vertically_stretchable = "on",
    padding = 1,
    border = {}
}

styles["surface_frame"] = {
    type = "frame_style",
    parent = "captionless_frame",
    padding = 8,
    horizontal_flow_style = {
        type = "horizontal_flow_style",
        horizontal_spacing = 0
    },
    horizontally_stretchable = "on",
    graphical_set = {}
    -- graphical_set = {
    --     base = {
    --         position = {17, 0},
    --         corner_size = 8,
    --         draw_type = "inner"
    --     }
    -- }
}

styles["surface_name_label"] = {
    type = "label_style",
    parent = "label",
    font = "heading-2",
    padding = 3
}

styles["ghost_frame"] = {
    type = "frame_style",
    parent = "inside_shallow_frame",
    padding = 0,
    margin = 0
}

styles["ghost_frame_red"] = {
    type = "frame_style",
    parent = "inside_shallow_frame",
    graphical_set = {
        draw_type = "inner",
        type = "composition",
        tint = {1, 0, 0},
        width = 1,
        height = 1
    }
}

styles["ghost_frame_green"] = {
    type = "frame_style",
    parent = "inside_shallow_frame",
    graphical_set = {
        draw_type = "inner",
        type = "composition",
        tint = {0, 1, 0},
        width = 1,
        height = 1
    }
}

styles["ghost_frame_orange"] = {
    type = "frame_style",
    parent = "inside_shallow_frame",
    graphical_set = {
        draw_type = "inner",
        type = "composition",
        tint = {1, 1, 0},
        width = 1,
        height = 1
    }

}
