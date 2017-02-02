//
//  russianBlockGameBoard.swift
//  superRussianBlocks
//
//  Created by nickgu on 17/1/28.
//  Copyright © 2017年 nickgu. All rights reserved.
//

import Foundation

enum RussianBlocksStatus : Int {
    case Going, Death, AllCleaned
}

class RussianBlocksCreator {
    var random_blocks : [[(x: Int, y: Int)]] = []
    
    init() {
        // L
        random_blocks.append([(-1, 0), (-1, 1), (-2, 1), (-3, 1)])
        // o
        random_blocks.append([(0, 0), (0, 1), (-1, 0), (-1, 1)])
        // |
        random_blocks.append([(0, 0), (-1, 0), (-2, 0), (-3, 0)])
        // .|.
        random_blocks.append([(0, 0), (-1, 0), (-1, -1), (-1, 1)])
        // s
        random_blocks.append([(0, 0), (0, 1), (-1, 1), (-1, 2)])
    }
    
    
    func create(board: inout [[Int]], movingBlocks: inout [(x: Int, y: Int)]) -> Bool {
        let height = board.count - 1
        let width = board[0].count
        let mid = width / 2
        
        let id = Int(arc4random()) % self.random_blocks.count
        
        for pos in self.random_blocks[id] {
            // insert the same blocks for debug
            if (board[height + pos.x][mid + pos.y] == 1) {
                // cannot insert.
                return false
            }
            board[height + pos.x][mid + pos.y] = 1
            movingBlocks.append( (x:height + pos.x, y:mid + pos.y) )
        }
        return true;
    }
}

class RussianBlockGameBoard {
    var board: [[Int]]
    var speed: Float // how many steps per seconds.
    var height: Int
    var width: Int
    var score: Int
    var creator: RussianBlocksCreator
    var movingBlocks: [(x: Int, y: Int)]
    
    init(width: Int, height: Int, speed: Float=1.0) {
        self.creator = RussianBlocksCreator()
        self.score = 0
        self.width = width
        self.height = height
        self.speed = speed
        self.board = []
        self.movingBlocks = []
        for _ in 0..<height {
            var m:[Int] = []
            for _ in 0..<width {
                m.append(0)
            }
            self.board.append(m)
        }
    }
    
    func one_step() ->
        (Status: RussianBlocksStatus,
        KilledLines : Int,
        TotalCount : Int)
    {
        // one step ahead.
        // ignore height 0
        var moving = true
        if self.movingBlocks.count == 0 {
            moving = false
        } else {
            for pos in self.movingBlocks {
                if pos.x-1==0 || self.board[pos.x-1][pos.y]>0 {
                    if !self.movingBlocks.contains(where: {x, y in
                        return (x==pos.x-1 && y==pos.y) })
                    {
                        moving = false
                        self.movingBlocks = []
                    }
                    
                }
            }
        }
        
        if moving {
            self.clearMovingBlocks()
            for i in 0..<self.movingBlocks.count {
                self.movingBlocks[i].x -= 1
            }
            self.redrawMovingBlocks()
        }
        
        // check whole line
        var status = RussianBlocksStatus.Going
        var blocks_count = 0
        var killed_lines : [Int] = []
        
        if !moving {
            // create new blocks
            let can_insert = self.creator.create(board: &self.board, movingBlocks: &self.movingBlocks)
            if !can_insert {
                status = RussianBlocksStatus.Death
            }
            
            // check killing
            for i in 0..<self.height {
                var killed = true
                var line_count = 0
                for j in 0..<self.width {
                    if self.board[i][j] == 0 {
                        killed = false
                    } else {
                        line_count += 1
                    }
                }
                blocks_count += line_count
                if killed {
                    killed_lines.append( i )
                }
            }
            
            killed_lines = killed_lines.sorted(by: {x, y in x>y})
            for i in killed_lines {
                self.killLine(i)
            }
        }
        
        self.score += killed_lines.count * killed_lines.count
        
        if blocks_count == 0 {
            status = RussianBlocksStatus.AllCleaned
        }
        
        return (status, killed_lines.count, blocks_count)
    }
    
    func left() {
        self.clearMovingBlocks()
        var tempMoving : [(x: Int, y: Int)] = []
        for pos in self.movingBlocks {
            tempMoving.append( (x: pos.x, y: pos.y-1) )
        }
        if self.check_available(tempMoving) {
            self.movingBlocks = tempMoving
        }
        self.redrawMovingBlocks()
    }
    
    func right() {
        self.clearMovingBlocks()
        var tempMoving : [(x: Int, y: Int)] = []
        for pos in self.movingBlocks {
            tempMoving.append( (x: pos.x, y: pos.y+1) )
        }
        if self.check_available(tempMoving) {
            self.movingBlocks = tempMoving
        }
        self.redrawMovingBlocks()
    }
    
    func rotate() {
        if self.movingBlocks.count == 0 {
            return
        }
        
        // left-top and left-button pos.
        var lt_pos : (x: Int, y: Int) = self.movingBlocks[0]
        var lb_pos : (x: Int, y: Int) = self.movingBlocks[0]
        for pos in self.movingBlocks {
            if pos.x < lb_pos.x {
                lb_pos.x = pos.x
            }
            if pos.x > lt_pos.x {
                lt_pos.x = pos.x
            }
            if pos.y < lt_pos.y {
                lt_pos.y = pos.y
                lb_pos.y = pos.y
            }
        }
    
        // transform each pos from offset-to-lt to offset-to-lb
        self.clearMovingBlocks()
        var tempMoving : [(x: Int, y: Int)] = []
        for i in 0..<self.movingBlocks.count {
            let off_x = self.movingBlocks[i].x - lt_pos.x
            let off_y = self.movingBlocks[i].y - lt_pos.y
            
            tempMoving.append( (x: lb_pos.x + off_y, y: lb_pos.y - off_x) )
        }
        if self.check_available(tempMoving) {
            self.movingBlocks = tempMoving
        }
        self.redrawMovingBlocks()
    }
    
    private func clearMovingBlocks() {
        for pos in self.movingBlocks {
            self.board[pos.x][pos.y] = 0
        }
    }
    
    private func redrawMovingBlocks() {
        for pos in self.movingBlocks {
            self.board[pos.x][pos.y] = 1
        }
    }
    
    private func killLine(_ line_id: Int) {
        self.clearMovingBlocks()
        for i in 0..<self.width {
            self.board[line_id][i] = 0
        }
        for l in line_id..<self.height-1 {
            for i in 0..<self.width {
                self.board[l][i] = self.board[l+1][i]
            }
        }
        self.redrawMovingBlocks()
    }
    
    private func check_available(_ movingBlocks: [(x: Int, y: Int)]) -> Bool {
        for pos in movingBlocks {
            if !(pos.x >= 0
                && pos.x < self.height
                && pos.y >= 0
                && pos.y < self.width
                && self.board[pos.x][pos.y] == 0
            )
            {
                return false
            }
        }
        return true
    }
}




