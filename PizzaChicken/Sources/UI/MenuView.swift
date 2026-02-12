//
//  MenuView.swift
//  PizzaChicken
//
//  Main menu view (optional)
//

import SwiftUI

struct MenuView: View {
    
    @State private var highScore: Int = 0
    
    var body: some View {
        VStack(spacing: 30) {
            // Title
            Text("Pizza Chicken")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // High Score Display
            VStack(spacing: 10) {
                Text("High Score")
                    .font(.headline)
                
                Text("\(highScore)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.orange)
            }
            
            // Play Button
            Button(action: startGame) {
                Text("Play")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 60)
                    .background(Color.green)
                    .cornerRadius(15)
            }
            
            // Leaderboard Button
            Button(action: showLeaderboard) {
                Text("Leaderboard")
                    .font(.body)
                    .foregroundColor(.blue)
            }
        }
        .onAppear {
            loadHighScore()
        }
    }
    
    private func loadHighScore() {
        highScore = ScoreManager.shared.highScore
    }
    
    private func startGame() {
        // TODO: Transition to game scene
        print("Starting game...")
    }
    
    private func showLeaderboard() {
        // TODO: Show Game Center leaderboard
        print("Showing leaderboard...")
    }
}

#Preview {
    MenuView()
}
