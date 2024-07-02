import SwiftUI

struct Coordinate: Equatable {
    var row, column: Int
}

enum Direction {
    case up, down, left, right
}

struct BoardState {
    var rows, columns: Int
    var food: Coordinate
    var player: [Coordinate]
    var direction: Direction = .right
    var isGameOver: Bool = false
}

struct ContentView: View {
    var body: some View {
        GameView()
    }
}

struct GameView: View {
    @StateObject private var gameViewModel = GameViewModel()
    
    var body: some View {
        VStack {
            Text("Score: \(gameViewModel.score)")
                .font(.headline)
                .padding()
            
            GeometryReader { geometry in
                ZStack {
                    GameBoard(boardState: gameViewModel.boardState, cellSize: geometry.size.width / CGFloat(gameViewModel.boardState.columns))
                    
                    if gameViewModel.boardState.isGameOver {
                        Text("Game Over!")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            
            HStack {
                ForEach([Direction.left, .up, .down, .right], id: \.self) { direction in
                    Button(action: {
                        gameViewModel.changeDirection(to: direction)
                    }) {
                        Image(systemName: directionArrow(for: direction))
                            .font(.title)
                            .padding()
                    }
                }
            }
            
            Button(action: gameViewModel.restartGame) {
                Text("Restart")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    func directionArrow(for direction: Direction) -> String {
        switch direction {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .left: return "arrow.left"
        case .right: return "arrow.right"
        }
    }
}

struct GameBoard: View {
    let boardState: BoardState
    let cellSize: CGFloat
    
    var body: some View {
        ZStack {
            ForEach(0..<boardState.rows, id: \.self) { row in
                ForEach(0..<boardState.columns, id: \.self) { column in
                    RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                        .fill(cellColor(at: Coordinate(row: row, column: column)))
                        .frame(width: cellSize, height: cellSize)
                        .position(x: CGFloat(column) * cellSize + cellSize / 2,
                                  y: CGFloat(row) * cellSize + cellSize / 2)
                }
            }
        }
    }
    
    func cellColor(at coordinate: Coordinate) -> Color {
        if boardState.player.contains(coordinate) {
            return .green
        } else if coordinate == boardState.food {
            return .red
        } else {
            return .gray.opacity(0.3)
        }
    }
}

class GameViewModel: ObservableObject {
    @Published var boardState: BoardState
    @Published var score: Int = 0
    
    private var timer: Timer?
    private let moveInterval: TimeInterval = 0.15
    
    init() {
        boardState = BoardState(rows: 20, columns: 20, food: Coordinate(row: 10, column: 10), player: [Coordinate(row: 0, column: 0)])
        startGame()
    }
    
    func startGame() {
        timer = Timer.scheduledTimer(withTimeInterval: moveInterval, repeats: true) { [weak self] _ in
            self?.move()
        }
    }
    
    func restartGame() {
        boardState = BoardState(rows: 20, columns: 20, food: Coordinate(row: 10, column: 10), player: [Coordinate(row: 0, column: 0)])
        score = 0
        timer?.invalidate()
        startGame()
    }
    
    func changeDirection(to newDirection: Direction) {
        let oppositeDirections: [Direction: Direction] = [.up: .down, .down: .up, .left: .right, .right: .left]
        if oppositeDirections[newDirection] != boardState.direction {
            boardState.direction = newDirection
        }
    }
    
    private func move() {
        guard !boardState.isGameOver else { return }
        
        var newHead = boardState.player.first!
        switch boardState.direction {
        case .up: newHead.row -= 1
        case .down: newHead.row += 1
        case .left: newHead.column -= 1
        case .right: newHead.column += 1
        }
        
        if isCollision(at: newHead) {
            boardState.isGameOver = true
            timer?.invalidate()
            return
        }
        
        boardState.player.insert(newHead, at: 0)
        
        if newHead == boardState.food {
            score += 1
            generateNewFood()
        } else {
            boardState.player.removeLast()
        }
    }
    
    private func isCollision(at coordinate: Coordinate) -> Bool {
        return coordinate.row < 0 || coordinate.row >= boardState.rows ||
               coordinate.column < 0 || coordinate.column >= boardState.columns ||
               boardState.player.contains(coordinate)
    }
    
    private func generateNewFood() {
        var newFood: Coordinate
        repeat {
            newFood = Coordinate(row: Int.random(in: 0..<boardState.rows),
                                 column: Int.random(in: 0..<boardState.columns))
        } while boardState.player.contains(newFood)
        boardState.food = newFood
    }
}
