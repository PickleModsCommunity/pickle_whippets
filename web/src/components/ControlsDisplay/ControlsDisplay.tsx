import { Group, Text } from "@mantine/core";
import { KeyboardKey } from "../KeyboardKey/KeyboardKey";
import { useState } from "react";
import classes from "./ControlsDisplay.module.css";
import { useNuiEvent } from "../NUI/useNui";

type Control = {
    key: string;
    action: string;
}

export function ControlsDisplay({defaultControls} : {defaultControls?: Control[]}) {
    const [visible, setVisible] = useState(false);
    const [opaque, setOpaque] = useState(false);
    const [controls, setControls] = useState<Control[]>(defaultControls || []);
    useNuiEvent("showControls", function(data) {
        if (!visible) {
            setVisible(true);
            setOpaque(false);
            setTimeout(() => {
                setOpaque(true);
            }, 50);
        }
        setControls(data.controls);
    });
    useNuiEvent("hideControls", function() {
        if (visible) {
            setOpaque(false);
            setTimeout(() => {
                setVisible(false);
            }, 250);
        }
    });
    return (!opaque && !visible) ? null : (
        <div className={classes.controlContainer} style={{opacity: (opaque ? 1 : 0)}}>
            {controls.map((control, index) => (
                <Group gap={10} key={index}>
                    <KeyboardKey>{control.key}</KeyboardKey>
                    <Text fw={"bold"}>{control.action}</Text>
                </Group>
            ))}
        </div>
    )
}