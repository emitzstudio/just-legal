//
//  DevConfig.swift
//  LexIndia
//
//  DEVELOPMENT ONLY configuration.
//
//  The permanent test access below exists so the product can be explored
//  during development without the 24-hour trial restriction.
//
//  BEFORE PRODUCTION:
//  Set `permanentTestAccessEnabled` to false (or delete this file and every
//  reference to it). That single flag removes the option from the paywall
//  AND invalidates any previously granted permanent test access.
//

import Foundation

enum DevConfig {
    /// DEVELOPMENT ONLY — gates the "permanent test access" entitlement.
    /// Must be `false` in production builds.
    static let permanentTestAccessEnabled = true
}
