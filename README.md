# ChessMentor ♟️ 
![image](https://github.com/user-attachments/assets/ec302138-d878-473d-9202-657dafdebc3a)

ChessMentor is an innovative iOS app that leverages augmented reality (AR) technology to analyze chess games and provide strategic move suggestions. By simply holding your device's camera above a chessboard, the app overlays helpful insights and recommendations directly onto the board, empowering players to make informed decisions and improve their gameplay.

### 🔗 Linked Repositories (Project Architecture)
ChessMentor is composed of multiple specialized repositories.  
This main repository serves as the **central hub**, while the following linked components handle data, ML training, and backend engine logic:

---

#### 📘 1. Dataset & Annotation (Roboflow)
- **Roboflow Workspace:**  
  https://universe.roboflow.com/chessmentor/chessmentor  

Contains all annotated chessboard datasets, preprocessing pipelines, and model versions used during training.

---

#### 🤖 2. Machine Learning Model (YOLOv11s Training)
- **ChessMentor-ML Repository:**  
  https://github.com/ObayAlshaer/ChessMentor-ML/tree/main  

Includes:
- YOLO training scripts  
- Data preprocessing  
- FEN generation tools  
- Validation and benchmarking notebooks  

---

#### ♟️ 3. Stockfish Evaluation API
- **Stockfish Flask API (Python):**  
  https://github.com/otoua046/stockfish-api  

Provides:
- REST endpoint for Stockfish best-move evaluation  
- Return format used by the iOS app  
- Engine configuration and depth settings  

---

### 🧩 High-Level Architecture

```text
          [iOS App UI]
                |
                v
     [Chessboard Scanner (Swift)]
                |
                v
      [Roboflow Inference API]
                |
                v
       [FEN Generator Logic]
                |
                v
     [Stockfish Flask API Server]
                |
                v
       [Best Move Suggestion]
```

## Features

- **Augmented Reality Chess Analysis**: Utilize AR technology to analyze chess positions in real-time.
- **Move Suggestions**: Receive intelligent move suggestions based on board positions and game analysis.
- **Camera Integration**: Seamlessly integrate your device's camera to capture and analyze chessboard positions.
- **User-Friendly Interface**: Enjoy a clean and intuitive interface designed for ease of use and accessibility.

## Usage

1. Launch the app and grant camera permissions when prompted.
2. Hold your device's camera above a chessboard with a game in progress.
3. Allow the app to analyze the board and suggest moves based on the current game state.
4. Review the suggested moves and make your decision accordingly.

## Acknowledgements

Special thanks to the contributors and maintainers of ARKit and SwiftUI for their valuable tools and frameworks.


## Author Information & Time spent

| Name                | Student Number | Time spent |        Email        |
|---------------------|----------------|------------|---------------------|
| Mohamed-Obay Alshaer | 300170489     |  100 hours  | malsh094@uottawa.ca |
| Sam Touahri         | 300234041      |  100 hours  | otoua046@uottawa.ca |
| Justin Bushfield    | 300188318      |  100 hours  | jbush023@uottawa.ca |
| Samuel Rose          | 300173591     |  100 hours  | srose096@uottawa.ca |
| Anas Hammou          | 300220367     |  100 hours  | ahamm073@uottawa.ca |

## Client Information 

| Name                | Affiliation    | Email                  |
|---------------------|----------------|------------------------|
|Omar Al-Dib          | CUSmile (Charity) | mromaldib@gmail.com    |
