//
//  Tools.swift
//  SpamFilter
//
//  Created by liangaiwu on 2019/9/3.
//  Copyright © 2019 liangaiwu. All rights reserved.
//

import Foundation

extension String {
     var words: [String] {
        
        return lowercased()
            .components(separatedBy: .punctuationCharacters)
            .joined()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter{!$0.isEmpty && $0.count > 2}
    }
}

public func TextToWordList(fileName: String) -> [String] {
    
    guard let path = Bundle.main.path(forResource:fileName, ofType:"txt"), let text = try? String(contentsOfFile:path, encoding: String.Encoding.utf8) else {
        return []
    }
    return text.words
}

fileprivate func GetAllWordAndLabel() -> ([[String]], [Double]){
    var emailWordList: [[String]] = []
    var emailLabelList: [Double] = []
    for i in 1...25 {
        emailWordList.append(TextToWordList(fileName: "ham\(i)"))
        emailLabelList.append(0.0)
        emailWordList.append(TextToWordList(fileName: "spam\(i)"))
        emailLabelList.append(1.0)
    }
    return (emailWordList, emailLabelList)
}

public func GetWordSetBy(wordList: [[String]]) -> [String] {
    var wordSet: [String] = []
    for words in wordList {
        for word in words {
            if (!wordSet.contains(word)) {
                wordSet.append(word)
            }
        }
    }
    return wordSet
    
}

public func wordsToVec(byWordSet wordSet: [String], andWordList wordList: [String]) -> [Double] {
    var vec: [Double] = [Double](repeating: 0.0, count: wordSet.count)
    for word in wordList {
        if let index = wordSet.firstIndex(of: word) {
            vec[index] = 1.0
        }
    }
    return vec
}


/// 统计垃圾性email出现概率，垃圾性邮件各单词出现的概率，非垃圾性email各单词出现概率
///
/// - Parameters:
///   - trainDataSet: 参与训练的数据集
///   - trainLabels: 训练数据的标签
/// - Returns: pShame：垃圾性email p0Vect：非垃圾性email中单词出现的概率 p1Vect：垃圾性email中单词出现的概率
fileprivate func trainNB0(trainDataSet: [[Double]], trainLabels: [Double]) -> (Double, [Double], [Double]) {
    let numTrains = trainDataSet.count     //训练数据的组数
    let numWords = trainDataSet[0].count   //每组训练数据的大小
    let pShame = trainLabels.reduce(0, +) / Double(numTrains)
    var p0Num = [Double](repeating: 1, count: numWords)           //存储统计非垃圾性邮件各单词出现频率
    var p1Num = [Double](repeating: 1, count: numWords)           //存储统计垃圾性邮件各单词出现频率
    for i in 0..<numTrains {
        if trainLabels[i] == 1.0 { //如果为垃圾性email
            for j in 0..<numWords {
                p1Num[j] = p1Num[j] + trainDataSet[i][j]
            }
        } else {
            for j in 0..<numWords {
                p0Num[j] = p0Num[j] + trainDataSet[i][j]
            }
        }
    }
    let p0SumWords = p0Num.reduce(0, +)         //计算非垃圾性邮件中单词总数
    let p1SumWords = p1Num.reduce(0, +)         //计算垃圾性邮件中单词总数
    var p0Vect = [Double](repeating: 0, count: numWords)          //非垃圾性邮件中单词出现的概率
    var p1Vect = [Double](repeating: 0, count: numWords)          //垃圾性邮件中单词出现的概率
    for i in 0..<numWords {
        p0Vect[i] = p0Num[i] / p0SumWords
        p1Vect[i] = p1Num[i] / p1SumWords
    }
    return (pShame,p0Vect,p1Vect)
}

/// 对email进行分类
///
/// - Parameters:
///   - vec2Classify: 要分类的数据
///   - p0Vect: 非垃圾性email中单词出现的概率
///   - p1Vect: 垃圾性email中单词出现的概率
///   - pShame: 垃圾性email
/// - Returns: 分类的结果，true表示垃圾性email,false表示非垃圾性email
fileprivate func classifyNB(vec2Classify: [Double], p0Vect: [Double], p1Vect: [Double], pShame: Double) -> Bool {
    var temp0: [Double] = []
    var temp1: [Double] = []
    for i in 0..<vec2Classify.count {
        temp0.append(vec2Classify[i] * p0Vect[i])
        temp1.append(vec2Classify[i] * p1Vect[i])
    }
    var p0 = (1.0 - pShame)
    var p1 = pShame
    for i in 0..<temp0.count {
        if temp0[i] != 0 {
            p0 *= temp0[i]
        }
        if temp1[i] != 0 {
            p1 *= temp1[i]
        }
    }
    print("垃圾邮件/正常邮件:\(p1 / p0)")
    return p1 > p0
}



/// 获取参数
fileprivate var GetParameters: (wordSet: [String], pShame: Double, p0Vect: [Double], p1Vect: [Double]) = {
    //准备数据
    let (emailWords, emailLabels) = GetAllWordAndLabel()
    let wordSet = GetWordSetBy(wordList: emailWords)
    var trainDatas: [[Double]] = []
    var trainLabels: [Double] = []
    for i in 0..<emailWords.count {
        let trainData = wordsToVec(byWordSet: wordSet, andWordList: emailWords[i])
        trainDatas.append(trainData)
        trainLabels.append(emailLabels[i])
    }
    //训练模型
    let (pShame, p0Vect, p1Vect) = trainNB0(trainDataSet: trainDatas, trainLabels: trainLabels)
    
    return (wordSet, pShame, p0Vect, p1Vect)
}()

/// 检测垃圾邮件
///
/// - Parameter email: 邮件内容
/// - Returns: 是否是垃圾邮件
public func CheckEmail(email: String) -> Bool {

    let testData: [Double] = wordsToVec(byWordSet: GetParameters.wordSet, andWordList: email.words)
    //使用模型
    return classifyNB(vec2Classify: testData, p0Vect: GetParameters.p0Vect, p1Vect: GetParameters.p1Vect, pShame: GetParameters.pShame)
    
}

/// 测试
public func test() {
    
    
    let testIndex = 5
    //准备数据
    let (emailWords, emailLabels) = GetAllWordAndLabel()
    let wordSet = GetWordSetBy(wordList: emailWords)
    var trainDatas: [[Double]] = []
    var trainLabels: [Double] = []
    for i in 0..<emailWords.count {
        let trainData = wordsToVec(byWordSet: wordSet, andWordList: emailWords[i])
        trainDatas.append(trainData)
        trainLabels.append(emailLabels[i])
    }
    
    //训练模型
    let (pShame, p0Vect, p1Vect) = trainNB0(trainDataSet: trainDatas, trainLabels: trainLabels)
    
     let testData: [Double] = wordsToVec(byWordSet: wordSet, andWordList: emailWords[testIndex])
    //使用模型
    let result = classifyNB(vec2Classify: testData, p0Vect: p0Vect, p1Vect: p1Vect, pShame: pShame) ? 1.0 : 0.0

    print("是否错误:\(result != emailLabels[testIndex])")
    
}
