// Import styles of packages that you've installed.
// All packages except `@mantine/hooks` require styles imports
import '@mantine/core/styles.css';

import { MantineProvider } from '@mantine/core';
import { ControlsDisplay } from './components/ControlsDisplay/ControlsDisplay';
import { ProcessStatus } from './components/ProcessStatus/ProcessStatus';
import { ConfigProvider } from './components/ConfigProvider/ConfigProvider';
import { Objective } from './components/Objective/Objective';

function ContentContainer() {
  return (
    <>
      <Objective />
      <ControlsDisplay />
      <ProcessStatus />
    </>
  );
}

export default function App() {
  return (
    <MantineProvider>
      <ConfigProvider>
        <ContentContainer/>
      </ConfigProvider>
    </MantineProvider>
  );
}
