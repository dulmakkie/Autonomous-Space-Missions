import { describe, it, beforeEach, expect } from "vitest"

describe("Funding Contract", () => {
  let mockStorage: Map<string, any>
  let tokenBalances: Map<string, number>
  
  beforeEach(() => {
    mockStorage = new Map()
    tokenBalances = new Map()
    tokenBalances.set("CONTRACT_OWNER", 1000000)
  })
  
  const mockContractCall = (method: string, args: any[], sender: string) => {
    switch (method) {
      case "fund-mission":
        const [missionId, amount] = args
        if ((tokenBalances.get(sender) || 0) < amount) {
          return { success: false, error: "ERR_INSUFFICIENT_FUNDS" }
        }
        tokenBalances.set(sender, (tokenBalances.get(sender) || 0) - amount)
        tokenBalances.set("CONTRACT_OWNER", (tokenBalances.get("CONTRACT_OWNER") || 0) + amount)
        const currentFunding = mockStorage.get(`mission-funding-${missionId}`)?.["total-funds"] || 0
        mockStorage.set(`mission-funding-${missionId}`, { "total-funds": currentFunding + amount })
        return { success: true }
      
      case "allocate-funds":
        const [allocateMissionId, allocateAmount, recipient] = args
        if (sender !== "CONTRACT_OWNER") return { success: false, error: "ERR_NOT_AUTHORIZED" }
        const missionFunds = mockStorage.get(`mission-funding-${allocateMissionId}`)?.["total-funds"] || 0
        if (missionFunds < allocateAmount) return { success: false, error: "ERR_INSUFFICIENT_FUNDS" }
        tokenBalances.set("CONTRACT_OWNER", (tokenBalances.get("CONTRACT_OWNER") || 0) - allocateAmount)
        tokenBalances.set(recipient, (tokenBalances.get(recipient) || 0) + allocateAmount)
        mockStorage.set(`mission-funding-${allocateMissionId}`, { "total-funds": missionFunds - allocateAmount })
        return { success: true }
      
      case "get-mission-funds":
        return { success: true, value: mockStorage.get(`mission-funding-${args[0]}`) }
      
      case "get-total-funds":
        return { success: true, value: tokenBalances.get("CONTRACT_OWNER") || 0 }
      
      default:
        return { success: false, error: "Unknown method" }
    }
  }
  
  it("should fund a mission", () => {
    tokenBalances.set("funder", 1000)
    const result = mockContractCall("fund-mission", [1, 500], "funder")
    expect(result.success).toBe(true)
    expect(tokenBalances.get("funder")).toBe(500)
    expect(tokenBalances.get("CONTRACT_OWNER")).toBe(1000500)
  })
  
  it("should not fund a mission with insufficient funds", () => {
    tokenBalances.set("funder", 100)
    const result = mockContractCall("fund-mission", [1, 500], "funder")
    expect(result.success).toBe(false)
    expect(result.error).toBe("ERR_INSUFFICIENT_FUNDS")
  })
  
  it("should not allocate funds if not authorized", () => {
    mockContractCall("fund-mission", [1, 1000], "funder")
    const result = mockContractCall("allocate-funds", [1, 500, "recipient"], "unauthorized")
    expect(result.success).toBe(false)
    expect(result.error).toBe("ERR_NOT_AUTHORIZED")
  })
})

