import { Group } from "@mantine/core";
import { useLocale } from "../Locale/Locale";
import { useState } from "react";
import classes from "./ProcessStatus.module.css";
import { useNuiEvent } from "../NUI/useNui";
import { useConfig } from "../ConfigProvider/ConfigProvider";

type ProcessStatus = {
    isOnline: boolean;
    progress: number;
    temperature: number;
}

export function ProcessStatus() {
    const { config } = useConfig();
    const Locale = useLocale();
    const [visible, setVisible] = useState(false);
    const [opaque, setOpaque] = useState(false);
    const [status, setStatus] = useState<ProcessStatus | null>(null);
    useNuiEvent("setProcessStatus", function(data) {
        if (!visible) {
            setVisible(true);
            setOpaque(false);
            setTimeout(() => {
                setOpaque(true);
            }, 50);
        }
        setStatus(data.status);
    });
    useNuiEvent("hideProcessStatus", function() {
        if (visible) {
            setOpaque(false);
            setTimeout(() => {
                setVisible(false);
                setStatus(null);
            }, 250);
        }
    });
    let isOnline = status?.isOnline || false;
    let progress = status?.progress || Math.floor(0);
    let temperature = status?.temperature || Math.floor(0);
    let temperatureDisplay = temperature + "°C";
    let temperatureElement = <b style={{color: "lightgreen"}}>{temperatureDisplay}</b>;
    if (temperature >= (config.gasProcess.Temperature + config.gasProcess.TemperatureRange)) {
        temperatureElement = <b style={{color: "lightcoral"}}>{temperatureDisplay}</b>;
    }
    else if (temperature <= (config.gasProcess.Temperature - config.gasProcess.TemperatureRange)) {
        temperatureElement = <b style={{color: "lightblue"}}>{temperatureDisplay}</b>;
    }
    return (!opaque && !visible) ? null : (
        <div className={classes.processContainer} style={{opacity: (opaque ? 1 : 0)}}>
            <Group gap={10} justify="space-between">
                <b>{Locale("stove_status")}: </b>
                {isOnline ? (<b style={{color: "lightgreen"}}>{Locale("online")}</b>) : (<b style={{color: "lightcoral"}}>{Locale("offline")}</b>)}
            </Group>
            <Group gap={10} justify="space-between">
                <b>{Locale("cook_progress")}: </b>
                <b>{progress}%</b>
            </Group>
            <Group gap={10} justify="space-between">
                <b>{Locale("temperature")}: </b>
                {temperatureElement}
            </Group>
        </div>
    );
}