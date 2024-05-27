#include <fstream>
#include <iostream>
#include <string>
#include <sstream>
#include <utility>
#include <vector>

struct TileInfo {
    int x, y;
    int id;
};

std::ostream& operator<<(std::ostream& o, TileInfo t) {
    o << '(' << t.x << ", " << t.y << ", " << t.id << ')';
    return o;
}

std::pair<std::vector<std::vector<TileInfo>>, bool> loadMap(const std::string& path) {
    std::vector<std::vector<TileInfo>> temp;

    std::ifstream file(path);
    bool success = false;

    if (!file.fail()) {
        success = true;
        std::cout << "Parsing file: " << path << "\n";

        int w, h;
        bool firstLine = false;

        std::string line;
        int i = 0;
        while (std::getline(file, line)) {
            if (!firstLine) {
                std::stringstream ss(line);
                ss >> w >> h;
                firstLine = true;
                continue;
            }
            
            temp.push_back(std::vector<TileInfo>());
            int j = 0;
            for (const char& c : line) {
                temp[i].push_back({(1 - w) / 2 + j, (h - 1) / 2 - i, c == ' ' ? 0 : (c == '#' ? 1 : (c == '.' ? 2 : (c == '=' ? 3 : 4)))});
                j++;
            }
            i++;
        }
    }
    else
        std::cout << "An error has occurred while reading the file.\n";

    file.close();
    return { temp, success };
}

void saveMap(const std::string& path, std::vector<std::vector<TileInfo>> map) {
    std::cout << "Saving at: " << path << '\n';
    std::ofstream file(path);

    if (!file.fail()) {
        for (const auto& row : map) {
            for (const auto& patch : row) {
                file << ' ' << patch.x << ' ' << patch.y << ' ' << patch.id;
            }
        }
        std::cout << "NetLogo-readable generated at: " << path << '\n';
    }
    else {
        std::cout << "An error has ocurred while saving the file.\n";
    }
    file.close();
}

std::pair<std::string, std::string> splitFileName(const std::string& filename) {
    std::string name;
    std::string extension;

    std::size_t i = filename.rfind('.', filename.length());

    if (i != std::string::npos) {
        name = filename.substr(0, i);
        extension = filename.substr(i + 1, filename.length() - 1);
        return { name, extension };
    }

    name = filename;
    extension = "";
    return { name, extension };
}

std::pair<std::string, std::pair<std::string, std::string>> splitPath(const std::string& path) {
    std::string absolutePath;
    std::string filename;
    
    std::size_t i = path.rfind('\\', path.length());
    
    if (i != std::string::npos) {
        absolutePath = path.substr(0, i);
        filename = path.substr(i + 1, path.length() - 1);
        return { absolutePath, splitFileName(filename) };
    }
    absolutePath = "";
    filename = path;
    
    return { absolutePath, splitFileName(filename) };
}

int main(int argc, char* argv[]) {
    if (argc > 1) {
        std::string inputFilePath = argv[1];
        auto pathInfo = splitPath(inputFilePath);
        std::string absolutePath = pathInfo.first;
        std::string filename = pathInfo.second.first;
        std::string extension = pathInfo.second.second;

        std::vector<std::vector<TileInfo>> map;
        bool successRead;
        
        auto mapInfo = loadMap(inputFilePath);
        map = mapInfo.first;
        successRead = mapInfo.second;
            
        if (successRead) {
            std::cout << "Map size: (" << map.size() << ", " << map[0].size() << ")\n";
            for (const auto& row : map) {
                for (const auto& patch : row)
                    std::cout << patch << ' ';
                std::cout << '\n';
            }

            std::string outputPath = absolutePath + "\\MAS4CHICKEN_" + filename + ".txt";
            saveMap(outputPath, map);
        }
        else
            std::cout << "No file has been created.\n";
    }
    else {
        std::cout << "Drag a txt file to this executable in order to initialize the conversion.\n";
    }
    std::cout << "Press enter to exit.\n";
    std::cin.get();

    return 0;
}