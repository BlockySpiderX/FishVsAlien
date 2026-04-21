export type PlotInstance = BasePart | Model

export type PlotSpawn = {
	index: number,
	instance: PlotInstance,
	spawnCFrame: CFrame,
}

export type PlotSnapshot = {
	index: number,
	ownerUserId: number?,
	ownerName: string?,
	isClaimed: boolean,
}

return nil
