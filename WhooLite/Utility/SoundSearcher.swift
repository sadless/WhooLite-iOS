//
//  SoundSearcher.swift
//  WhooLite
//
//  Created by 안영건 on 2016. 7. 28..
//  Copyright © 2016년 영건닷컴. All rights reserved.
//

import UIKit

/**
 * 초성 검색 알고리즘을 위한 클래스 이다.
 *
 * @author roter
 *         http://www.roter.pe.kr
 *
 *         사용 법은 평범하다.
 *
 *         SoundSearcher.matchString("검색할대상","검색어");
 *         ex)
 *         SoundSearcher.matchString("안녕하세요","ㅇㄴ하"); //true
 *         SoundSearcher.matchString("반갑습니다","ㅂㄱ습ㄴ"); //true
 *         SoundSearcher.matchString("안녕히가세요","ㅇㄴㅎㅎ"); //false
 
 *         TRUE가 리턴 되면 찾은 것이다
 */
class SoundSearcher: NSObject {
    static let hangulBeginUnicode = UInt32(44032) // 가
    static let hangulLastUnicode = UInt32(55203) // 힣
    static let hangulBaseUnit = UInt32(588) //각자음 마다 가지는 글자수
    //자음
    static let initialSound = ["ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ", "ㅃ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ", "ㅌ", "ㅍ", "ㅎ"]
    
    /**
     * 해당 문자가 INITIAL_SOUND인지 검사.
     *
     * @param searchar
     * @return
     */
    static fileprivate func isInitialSound(_ searchar: String) -> Bool {
        for c in initialSound {
            if c == searchar {
                return true
            }
        }
        
        return false
    }
    
    /**
     * 해당 문자의 자음을 얻는다.
     *
     * @param c 검사할 문자
     * @return
     */
    static fileprivate func getInitialSound(_ c: String) -> String {
        let hanBegin = (c.unicodeScalars.first?.value)! - hangulBeginUnicode
        let index = Int(hanBegin / hangulBaseUnit)
        
        return initialSound[index]
    }
    
    /**
     * 해당 문자가 한글인지 검사
     *
     * @param c 문자 하나
     * @return
     */
    static fileprivate func isHangul(_ c: String) -> Bool {
        let value = (c.unicodeScalars.first?.value)!
        
        return hangulBeginUnicode <= value && value <= hangulLastUnicode
    }
    
    /**
     * 생성자.
     */
//    public SoundSearcher() {
//    }
    
    /**
     * 검색을 한다. 초성 검색 완벽 지원함.
     *
     * @param value  : 검색 대상 ex> 초성검색합니다
     * @param search : 검색어 ex> ㅅ검ㅅ합ㄴ
     * @return 매칭 되는거 찾으면 true 못찾으면 false.
     */
    static func matchString(_ value: String, search: String) -> Bool {
        var t: Int
        let seof = value.characters.count - search.characters.count
        let slen = search.characters.count
        
        if seof < 0 {
            return false //검색어가 더 길면 false를 리턴한다.
        }
        for i in 0...seof {
            t = 0
            while t < slen {
                let index = search.index(search.startIndex, offsetBy: t)
                var check = search.substring(from: index)
                
                check = check.substring(to: check.index(check.startIndex, offsetBy: 1))
                
                let index2 = value.index(value.startIndex, offsetBy: i + t)
                var check2 = value.substring(from: index2)
                
                check2 = check2.substring(to: check2.index(check2.startIndex, offsetBy: 1))
                
                if isInitialSound(check) && isHangul(check2) {
                    //만약 현재 char이 초성이고 value가 한글이면
                    if getInitialSound(check2) == check {
                        //각각의 초성끼리 같은지 비교한다
                        t += 1
                    } else {
                        break
                    }
                } else {
                    //char이 초성이 아니라면
                    if check2 == check {
                        //그냥 같은지 비교한다.
                        t += 1
                    } else {
                        break
                    }
                }
            }
            if t == slen {
                return true //모두 일치한 결과를 찾으면 true를 리턴한다.
            }
        }
        
        return false //일치하는 것을 찾지 못했으면 false를 리턴한다.
    }
}
