import React, { createContext, useContext, useState, ReactNode } from 'react';
import { useNuiEvent } from '../NUI/useNui';

type Locale = {
    [key: string]: string;
}

type Config = {
    loaded?: boolean;
    locale: Locale;
    gasProcess: {
        ProgressPerTick: number;
        OvercookExplosionTicks: number;
        HeatPerTick: number;
        Temperature: number;
        TemperatureRange: number;
    };
}

interface ConfigContextProps {
    config: Config;
    setConfig: (newConfig: Config) => void;
}

const ConfigContext = createContext<ConfigContextProps | undefined>(undefined);

interface ConfigProviderProps {
    children: ReactNode;
}

export const ConfigProvider: React.FC<ConfigProviderProps> = ({ children }) => {
    const [config, setConfig] = useState<Config>({
        locale: {},
        gasProcess: {
            ProgressPerTick: 0,
            OvercookExplosionTicks: 0,
            HeatPerTick: 0,
            Temperature: 0,
            TemperatureRange: 0,
        },
    });

    useNuiEvent("setConfig", function(config) {
      setConfig(config);
    });

    return (
        <ConfigContext.Provider value={{ config, setConfig }}>
            {children}
        </ConfigContext.Provider>
    );
};

export const useConfig = (): ConfigContextProps => {
    const context = useContext(ConfigContext);
    if (!context) {
        throw new Error('useConfig must be used within a ConfigProvider');
    }
    return context;
};