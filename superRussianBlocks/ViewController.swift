//
//  ViewController.swift
//  superRussianBlocks
//
//  Created by nickgu on 17/1/28.
//  Copyright © 2017年 nickgu. All rights reserved.
//

import UIKit
import SpriteKit


class MultiLineNode : SKNode {
    var lineCount = 5
    var fontSize = 20.0
    var lines : [String] = []
    var lineLabels : [SKLabelNode] = []
    
    func create(lineCount: Int=5, fontSize: Double=20.0) {
        self.lineCount = lineCount
        
        for i in 1...self.lineCount {
            let line = SKLabelNode()
            let y = CGFloat( Double(-i) * (self.fontSize+3))
            line.position = CGPoint(x: 10, y: y)
            line.fontSize = CGFloat(self.fontSize)
            line.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
            line.text = "info\(i): \(y)"
            self.lineLabels.append(line)
            self.addChild(line)
        }
    }
    
    func appendLog(line: String) {
        self.lines.append(line)
        if self.lines.count > self.lineCount {
            self.lines.remove(at: 0)
        }
        for i in 0..<self.lines.count {
            self.lineLabels[i].text = self.lines[i]
        }
    }
}

class DeviceManager {
    var screenWidth : CGFloat = -1
    var screenHeight : CGFloat = -1
    
    func attachDevice(_ viewSize: CGSize) {
        self.screenHeight = viewSize.height
        self.screenWidth = viewSize.width
    }
    
    func widthRatio(_ ratio:Float) -> CGFloat {
        return CGFloat(ratio) * self.screenWidth
    }
    
    func heightRatio(_ ratio:Float) -> CGFloat {
        return CGFloat(ratio) * self.screenHeight
    }
}
var g_globalDevice: DeviceManager = DeviceManager()


class LeftButton : SKShapeNode {
    var board : RussianBlockGameBoard?
    var log : MultiLineNode?
    
    func create(board: RussianBlockGameBoard, console: MultiLineNode) {
        self.isUserInteractionEnabled = true
        self.board = board
        self.log = console
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.board!.left()
        log?.appendLog(line: "OP: left.")
    }
}

class RightButton : SKShapeNode {
    var board : RussianBlockGameBoard?
    var log : MultiLineNode?
    
    func create(board: RussianBlockGameBoard, console: MultiLineNode) {
        self.isUserInteractionEnabled = true
        self.board = board
        self.log = console
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.board!.right()
        log?.appendLog(line: "OP: right.")
    }
}


class RotateButton : SKShapeNode {
    var board : RussianBlockGameBoard?
    var log : MultiLineNode?
    
    func create(board: RussianBlockGameBoard, console: MultiLineNode) {
        self.isUserInteractionEnabled = true
        self.board = board
        self.log = console
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.board!.rotate()
        log?.appendLog(line: "OP: rotate.")
    }
}

class PauseButton : SKShapeNode {
    var board : RussianBlockGameBoard?
    var log : MultiLineNode?
    
    func create(board: RussianBlockGameBoard, console: MultiLineNode) {
        self.isUserInteractionEnabled = true
        self.board = board
        self.log = console
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.board!.togglePause()
        log?.appendLog(line: "OP: pause.")
    }
}

class GameScene : SKScene {
    var board : RussianBlockGameBoard?
    var timer : Timer?
    var log : MultiLineNode = MultiLineNode()
    var score_label : SKLabelNode?
    var blocks : [[SKShapeNode]] = []
    
    override func didMove(to view: SKView) {
        // present russian blocks' main node and next-block-node.
        
        self.log.position = CGPoint(x: 20, y: 400)
        self.log.create(lineCount: 10, fontSize: 30.0)
        self.addChild(self.log)
        
        self.board = RussianBlockGameBoard(width: 10, height: 20)
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: update)

        let buttonRadius = g_globalDevice.widthRatio(0.18 / 2.0)
        if let board = self.board {
            let leftButton = LeftButton(circleOfRadius: buttonRadius)
            leftButton.create(board: board, console: self.log)
            leftButton.position = CGPoint(
                x: g_globalDevice.widthRatio(0.225),
                y: g_globalDevice.heightRatio(0.2))
            leftButton.fillColor = UIColor.white
            self.addChild(leftButton)
            
            let rightButton = RightButton(circleOfRadius: buttonRadius)
            rightButton.create(board: board, console: self.log)
            rightButton.position = CGPoint(
                x: g_globalDevice.widthRatio(1.0 - 0.225),
                y: g_globalDevice.heightRatio(0.2))
            rightButton.fillColor = UIColor.white
            self.addChild(rightButton)
            
            let rotateButton = RotateButton(circleOfRadius: buttonRadius)
            rotateButton.create(board: board, console: self.log)
            rotateButton.position = CGPoint(
                x: g_globalDevice.widthRatio(0.5),
                y: g_globalDevice.heightRatio(0.2))
            rotateButton.fillColor = UIColor.white
            self.addChild(rotateButton)
            
            let pauseButton = PauseButton(circleOfRadius: buttonRadius)
            pauseButton.create(board: board, console: self.log)
            pauseButton.position = CGPoint(
                x: g_globalDevice.widthRatio(0.1),
                y: g_globalDevice.heightRatio(0.85))
            pauseButton.fillColor = UIColor.white
            self.addChild(pauseButton)
            
            /*
            let alphaScreen = SKShapeNode(rect: (self.view?.bounds)!)
            alphaScreen.fillColor = UIColor.black
            alphaScreen.alpha = CGFloat(0.1)
            self.addChild(alphaScreen)
            */
            self.score_label = SKLabelNode(text: "(scores here)")
            if let score_label = self.score_label {
                score_label.fontSize = g_globalDevice.heightRatio(0.1)
                
                score_label.horizontalAlignmentMode = .center
                score_label.position = CGPoint(
                    x: g_globalDevice.widthRatio(0.5),
                    y: g_globalDevice.heightRatio(0.85)
                )
                self.addChild(score_label)
            }
        }
        
        prepareBoard(board: (self.board?.board)!)
    }
    
    func update(timer: Timer) {
        if let ret = self.board?.one_step() {
            self.log.appendLog(line: String(format: "Status:%d KilledLine(s) %d total:%d",
                                            ret.Status.rawValue,
                                            ret.KilledLines,
                                            ret.TotalCount))
            
            self.updateBoard(board: (self.board?.board)!)
            
        } else {
            self.log.appendLog(line: "bad returns.")
        }
    }
    
    func prepareBoard(board: [[RussianBlocksColors]]) {
        let height = board.count
        let width = board[0].count
        self.blocks = []
        
        
        let leftBottom = CGPoint(
            x: g_globalDevice.widthRatio(0.25),
            y: g_globalDevice.heightRatio(0.3)
        )
        
        let widthBoarderSize = g_globalDevice.widthRatio(0.5 / Float(board[0].count) / 11.0)
        let heightBoarderSize = g_globalDevice.heightRatio(0.5 / Float(board.count) / 11.0)
        
        let blockSize = CGSize(
            width: g_globalDevice.widthRatio(0.5 / Float(board[0].count) * 10.0 / 11.0),
            height: g_globalDevice.heightRatio(0.5 / Float(board.count) * 10.0 / 11.0)
        )
        
        for i in 0..<height {
            var row : [SKShapeNode] = []
            for j in 0..<width {
                let origin = CGPoint(
                    x: CGFloat(j)*(blockSize.width + widthBoarderSize) + CGFloat(leftBottom.x),
                    y: CGFloat(i)*(blockSize.height + heightBoarderSize) + CGFloat(leftBottom.y)
                )
                let b = SKShapeNode(
                    rect: CGRect(origin: origin, size: blockSize),
                    cornerRadius: widthBoarderSize
                )
                b.fillColor = UIColor.white
                b.isHidden = true
                row.append(b)
                self.addChild(b)
            }
            self.blocks.append(row)
        }
    }
    
    func updateBoard(board: [[RussianBlocksColors]]) {
        let height = board.count
        let width = board[0].count
        
        self.score_label?.text = String(format: "%d", self.board!.score)
        
        for i in 0..<height {
            for j in 0..<width {
                if board[i][j] != RussianBlocksColors.Empty {
                    self.blocks[i][j].isHidden = false
                    switch board[i][j] {
                    case RussianBlocksColors.Cyan:
                        self.blocks[i][j].fillColor = UIColor.cyan
                    case RussianBlocksColors.Blue:
                        self.blocks[i][j].fillColor = UIColor.blue
                    case RussianBlocksColors.Green:
                        self.blocks[i][j].fillColor = UIColor.green
                    case RussianBlocksColors.Orange:
                        self.blocks[i][j].fillColor = UIColor.orange
                    case RussianBlocksColors.Purple:
                        self.blocks[i][j].fillColor = UIColor.purple
                    case RussianBlocksColors.Red:
                        self.blocks[i][j].fillColor = UIColor.red
                    case RussianBlocksColors.Yellow:
                        self.blocks[i][j].fillColor = UIColor.yellow
                    default:
                        self.blocks[i][j].fillColor = UIColor.black
                    }
                } else {
                    self.blocks[i][j].isHidden = true
                }
            }
        }
    }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let view = self.view as! SKView
        g_globalDevice.attachDevice(self.view.bounds.size)
        
        let scene = GameScene(size: self.view.bounds.size)
        scene.backgroundColor = UIColor.black
        view.presentScene(scene)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

