#include <fstream>
#include <iostream>
#include <string>
#include <sstream>
#include <utility>
#include <vector>

// Basic structure to save patch information
struct TileInfo {
    int x, y;
    float color;
};

// Output support for the TileInfo class
std::ostream& operator<<(std::ostream& o, TileInfo t) {
    o << '(' << t.x << ", " << t.y << ", " << t.color << ')';
    return o;
}

/*
    Handles convertion from symbol to the equivalent of NetLogo color value
    ' ' -> 45 // Yellow
    '#' ->  0 // Black
    '.' ->  5 // Gray
    '=' -> 35 // Brown
    '*' -> 65 // Green
    '@' -> 27 // Orange + 2
    'C' ->  4 // Gray - 1
*/
float symbol2col(char c) {
    switch (c) {
    default:
    case ' ': return 45.0f; // Restaurant
    case '#': return  0.0f; // Walls
    case '.': return  5.0f; // Staff
    case '=': return 35.0f; // Tables
    case '*': return 65.0f; // Outside
    case '@': return 27.0f; // Client spawn
    case 'C': return  4.0f; // Cook spawn
    }
}

// After reading a map, it returns a pair of values: The resulting map, and a "successful read" flag. Always evaluate the second value first!
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
                temp[i].push_back({
                    (1 - w) / 2 + j,
                    (h - 1) / 2 - i,
                    symbol2col(c)
                });
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
        file << '[';
        /*
        // Add a few black colored layers to make room for the images in the NetLogo interface (Deprecated feature!)
        for (int i = 15; i > 12; i--) {
            for (int j = -12; j < 12; j++) {
                file << ' ' << j << ' ' << i << ' ' << 0;
            }
        }
        */
        // Store map info in groups of 3: x, y, color
        for (const auto& row : map)
            for (const auto& patch : row)
                file << ' ' << patch.x << ' ' << patch.y << ' ' << patch.color;
        file << ']';
        std::cout << "NetLogo-readable generated at: " << path << '\n';
    }
    else
        std::cout << "An error has ocurred while saving the file.\n";
    file.close();
}

// Splits a file name into its main components: name and extension
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

// Splits a file path into two components: absolute path and filename (extension included. See "splitFileName" for further information)
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

/*
    This program executes with the following parameters:
        - Executable path
        - File(s) to convert (optional)
    
    NOTE: As of now, it is advised to put the desired files to convert into the same location as the executable.
*/
int main(int argc, char* argv[]) {
    if (argc > 1)
        for (int i = 1; i < argc; i++) {
            std::string inputFilePath = argv[i];
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

                std::string outputPath = absolutePath + "\\generated\\MAS4CHICKEN_" + filename + ".txt";
                saveMap(outputPath, map);
            }
            else
                std::cout << "No file has been created.\n";
        }
    else
        std::cout << "Drag a txt file to this executable in order to initialize the conversion.\n";
    
    std::cout << "Press enter to exit.\n";
    std::cin.get();

    return 0;
}