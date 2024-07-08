//
//  SatoText.swift
//  Seedkeeper
//
//  Created by Lionel Delvaux on 17/04/2024.
//

import Foundation
import SwiftUI

enum SatoTextStyle {
    case title
    case titleWhite
    case lightTitle
    case lightTitleDark
    case lightTitleSmall
    case subtitle
    case lightSubtitle
    case lightSubtitleDark
    case extraLightSubtitle
    case subtitleBold
    case viewTitle
    case cellTitle
    case slotTitle
    case balanceLarge
    case cellSmallTitle
    //SeedKeeper:
    case SKMenuItemTitle
    case SKMenuItemSubtitle
    case SKStrongBodyDark
    case SKStrongBodyLight
    
    var lineHeight: CGFloat {
        switch self {
        case .title, .titleWhite:
            return 38
        case .subtitle, .lightSubtitle, .lightSubtitleDark:
            return 20
        case .extraLightSubtitle:
            return 16
        case .subtitleBold:
            return 20
        case .viewTitle:
            return 36
        case .cellTitle:
            return 20
        case .slotTitle:
            return 57
        case .balanceLarge:
            return 35
        case .lightTitle, .lightTitleDark:
            return 26
        case .lightTitleSmall:
            return 22
        case .cellSmallTitle:
            return 16
        case .SKMenuItemTitle:
            return 24
        case .SKMenuItemSubtitle:
            return 18
        case .SKStrongBodyDark:
            return 24
        case .SKStrongBodyLight:
            return 24
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .title, .titleWhite:
            return 30
        case .subtitle:
            return 15
        case .subtitleBold:
            return 16
        case .viewTitle:
            return 24
        case .cellTitle:
            return 16
        case .slotTitle:
            return 45
        case .balanceLarge:
            return 28
        case .lightTitle, .lightTitleDark:
            return 24
        case .lightTitleSmall:
            return 20
        case .cellSmallTitle:
            return 14
        case .lightSubtitle, .lightSubtitleDark:
            return 20
        case .extraLightSubtitle:
            return 13
        case .SKMenuItemTitle:
            return 16
        case .SKMenuItemSubtitle:
            return 14
        case .SKStrongBodyDark:
            return 16
        case .SKStrongBodyLight:
            return 16
        }
    }

    var font: Font {
        switch self {
        case .title, .titleWhite, .cellTitle, .balanceLarge, .lightTitle, .lightTitleDark, .lightTitleSmall, .cellSmallTitle, .extraLightSubtitle:
            return .custom("Outfit-Medium", size: self.fontSize)
        case .subtitle, .SKMenuItemTitle:
            return .custom("OpenSans-variable", size: self.fontSize)
        case .viewTitle:
            return .custom("Poppins-ExtraBold", size: self.fontSize)
        case .subtitleBold:
            return .custom("Outfit-Bold", size: self.fontSize)
        case .slotTitle, .lightSubtitle, .SKMenuItemSubtitle, .lightSubtitleDark:
            return .custom("Outfit-ExtraLight", size: self.fontSize)
        case .SKStrongBodyDark:
            return .custom("OpenSans-Medium", size: self.fontSize)
        case .SKStrongBodyLight:
            return .custom("OpenSans-Medium", size: self.fontSize)
        }
    }

    var textColor: Color {
        switch self {
        case .title, .lightTitle, .lightTitleSmall, .lightTitleDark, .lightSubtitleDark:
            return .black
        case .titleWhite:
            return .white
        case .subtitle, .lightSubtitle, .extraLightSubtitle:
            return .white
        case .subtitleBold:
            return .white
        case .viewTitle:
            return .white
        case .cellTitle:
            return .white
        case .slotTitle:
            return .white
        case .balanceLarge:
            return .white
        case .cellSmallTitle:
            return .white
        case .SKMenuItemTitle, .SKMenuItemSubtitle:
            return .black
        case .SKStrongBodyDark:
            return .black
        case .SKStrongBodyLight:
            return .white
        }
    }

    var fontWeight: Font.Weight {
        switch self {
        case .title, .titleWhite, .subtitleBold:
            return .bold
        case .subtitle, .lightSubtitle, .cellTitle, .extraLightSubtitle, .lightSubtitleDark:
            return .regular
        case .viewTitle:
            return .bold
        case .slotTitle:
            return .ultraLight
        case .balanceLarge, .lightTitle, .lightTitleDark, .lightTitleSmall, .cellSmallTitle:
            return .medium
        case .SKMenuItemTitle:
            return .regular
        case .SKMenuItemSubtitle:
            return .ultraLight
        case .SKStrongBodyDark:
            return .regular
        case .SKStrongBodyLight:
            return .regular
        }
    }
}


struct SatoText: View {
    
    var text: String
    var style: SatoTextStyle
    var alignment: TextAlignment = .center
    var forcedColor: Color? = nil

    var body: some View {
        Text(.init(text))
            .font(style.font)
            .lineSpacing(style.lineHeight - style.fontSize)
            .multilineTextAlignment(alignment)
            .foregroundColor(forcedColor ?? style.textColor)
    }
}
