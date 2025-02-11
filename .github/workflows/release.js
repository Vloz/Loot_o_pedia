const fs = require('fs');
const path = require('path');
const archiver = require('archiver');
const strip = require('strip-comments');

//! Not safe lua comments trimmer, may lead to unexpected behaviour on release side
function removeComments(filePath, language) {
    let content = fs.readFileSync(filePath, 'utf8');
    content = strip(content, { language })
    fs.writeFileSync(filePath, content, 'utf8');

}

function updateVersionAndDebug(filePath, major, minor) {
    let content = fs.readFileSync(filePath, 'utf8');
    content = content.replace(/ns\.MAJOR\s*=\s*\d+/, `ns.MAJOR = ${major}`);
    content = content.replace(/ns\.MINOR\s*=\s*\d+/, `ns.MINOR = ${minor}`);
    content = content.replace(/ns\.IS_DEBUG\s*=\s*true/, 'ns.IS_DEBUG = false');
    fs.writeFileSync(filePath, content, 'utf8');
}

function shouldInclude(filePath, excludeList) {
    if (excludeList && excludeList.length > 0) {
        return !excludeList.some(pattern => filePath.includes(pattern));
    }
    return true;
}

function processFiles(directory, tag, excludeList) {
    const files = fs.readdirSync(directory);
    files.forEach(file => {
        const filePath = path.join(directory, file);
        const stat = fs.statSync(filePath);
        if (stat.isDirectory()) {
            processFiles(filePath, tag, excludeList);
        } else if (file.endsWith('.lua') || file.endsWith('.xml')) {
            if (shouldInclude(filePath, excludeList) && !filePath.includes('Libs')) {
                const ext = file.slice(-3).toLowerCase()
                if (['lua', 'xml'].includes(ext))
                    removeComments(filePath, file.slice(-3));
                if (path.basename(filePath) === 'core.lua') {
                    const [major, minor] = tag.slice(1).split('.');
                    updateVersionAndDebug(filePath, major, minor);
                }
            }
        }
    });
}

function createZip(directory, outputZip, parentDir, excludeList) {
    const output = fs.createWriteStream(outputZip);
    const archive = archiver('zip', {
        zlib: { level: 9 }
    });

    output.on('close', () => {
        console.log(`${archive.pointer()} total bytes`);
        console.log('Zip file created at:', outputZip);
    });

    archive.on('error', (err) => {
        throw err;
    });

    archive.pipe(output);

    const files = fs.readdirSync(directory);
    files.forEach(file => {
        const filePath = path.join(directory, file);
        const stat = fs.statSync(filePath);
        if (stat.isDirectory()) {
            addFilesToZip(archive, filePath, directory, parentDir, excludeList);
        } else if (shouldInclude(filePath, excludeList)) {
            archive.file(filePath, { name: path.join(parentDir, path.relative(directory, filePath)) });
        }
    });

    archive.finalize();
}

function addFilesToZip(archive, dir, baseDir, parentDir, excludeList) {
    const files = fs.readdirSync(dir);
    files.forEach(file => {
        const filePath = path.join(dir, file);
        const stat = fs.statSync(filePath);
        if (stat.isDirectory()) {
            addFilesToZip(archive, filePath, baseDir, parentDir, excludeList);
        } else if (shouldInclude(filePath, excludeList)) {
            archive.file(filePath, { name: path.join(parentDir, path.relative(baseDir, filePath)) });
        }
    });
}

function main() {
    const args = process.argv.slice(2);
    const tag = args.find(arg => arg.startsWith('--tag='))?.split('=')[1];
    const outputZip = args.find(arg => arg.startsWith('--output='))?.split('=')[1];
    const parentDir = args.find(arg => arg.startsWith('--parent-dir='))?.split('=')[1];

    const excludeListPath = path.join(__dirname, 'exclude_list.txt');
    let excludeList = [];

    if (fs.existsSync(excludeListPath)) {
        excludeList = fs.readFileSync(excludeListPath, 'utf8').split('\n').map(line => line.trim()).filter(Boolean);
    }

    const sourcesDirectory = '.';
    processFiles(sourcesDirectory, tag, excludeList);
    createZip(sourcesDirectory, outputZip, parentDir, excludeList);
}

main();