import { Group, Text } from "@mantine/core";
import { useState } from "react";
import { useNuiEvent } from "../NUI/useNui";
import classes from "./Objective.module.css";

export function Objective() {
    const [visible, setVisible] = useState(false);
    const [opaque, setOpaque] = useState(false);
    const [title, setTitle] = useState<string | null>(null);
    const [text, setText] = useState<string | null>(null);
    useNuiEvent("setObjective", function(objective) {
        if (!visible) {
            setVisible(true);
            setOpaque(false);
            setTimeout(() => {
                setOpaque(true);
            }, 50);
        }
        setTitle(objective.title || null);
        setText(objective.text || null);
    });
    useNuiEvent("hideObjective", function() {
        if (visible) {
            setOpaque(false);
            setTimeout(() => {
                setVisible(false);
            }, 250);
        }
    });

    return ((!opaque && !visible) || (title == null && text == null)) ? null : (
        <div className={classes.objectiveContainer} style={{ opacity: (opaque ? 1 : 0)}}>
            <Group gap={10}>
                {title ? <Text fz={24} fw={"bold"}>{title}:</Text> : null}
                {text ? <Text fz={24} fw={400}>{text}</Text> : null}
            </Group>
        </div>
    );
}