import fs from "fs";
import path from "path";

export default (folderPath: string): string[] => {
    return fs.readdirSync(folderPath).filter(file =>
        fs.statSync(path.join(folderPath, file)).isFile()
    );
}