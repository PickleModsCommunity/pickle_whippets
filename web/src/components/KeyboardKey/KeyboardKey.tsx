import { useLocale } from "../Locale/Locale";
import { Group } from "@mantine/core";

function IconMouse() {
    return (<svg xmlns="http://www.w3.org/2000/svg" width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M6 3m0 4a4 4 0 0 1 4 -4h4a4 4 0 0 1 4 4v10a4 4 0 0 1 -4 4h-4a4 4 0 0 1 -4 -4z"></path><path d="M12 3v7"></path><path d="M6 10h12"></path></svg>);
}

export function KeyboardKey({ children }: { children: any }) {
    const Locale = useLocale();
    let keyElement = children;
    if (keyElement === " ") {
        keyElement = Locale("key_spacebar")
    }
    else if (keyElement === "LeftClick") {
        return (
            <Group style={{position: "relative"}}>
                <IconMouse/>
                <div style={{background: "white", position:"absolute", left: 8, top: 5, width: 6, height: 7, border: "grey solid 1px", borderTopLeftRadius: 5}}></div>
            </Group>
        )
    }
    else if (keyElement === "RightClick") {
        return (
            <Group style={{position: "relative"}}>
                <IconMouse/>
                <div style={{background: "white", position:"absolute", left: 16, top: 5, width: 6, height: 7, border: "grey solid 1px", borderTopRightRadius: 5}}></div>
            </Group>
        )
    }
    let longKey = (keyElement.length > 1);
    return (!longKey) ? (
        <div style={{color: "black", backgroundColor: "white", width: 30, height: 30, borderRadius: 5, display: "flex", alignItems: "center", justifyContent: "center"}}>
            <b>{keyElement}</b>
        </div>
    ) : (
        <div style={{color: "black", backgroundColor: "white", paddingLeft: 10, paddingRight: 10, paddingTop: 3, paddingBottom: 3, borderRadius: 5, display: "flex", alignItems: "center", justifyContent: "center"}}>
            <b>{keyElement}</b>
        </div>
    );
}