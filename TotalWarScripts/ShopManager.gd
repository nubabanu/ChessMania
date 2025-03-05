extends Node

signal money_changed  

var money: int = 200  

func spend_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		print("💰 Money spent! New balance:", money)
		money_changed.emit()
		return true
	print("⚠️ Not enough money! Current balance:", money)
	return false
