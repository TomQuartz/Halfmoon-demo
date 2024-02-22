package core

import (
	"github.com/aws/aws-sdk-go/aws"
	"github.com/eniac/Beldi/pkg/cayonlib"
)

func WritePlot(env *cayonlib.Env, plotId string, plot string) {
	cayonlib.Write(env, TPlot(), plotId, map[string]interface{}{
		"V": aws.JSONValue{"plotId": plotId, "plot": plot},
	})
}

func ReadPlot(env *cayonlib.Env, plotId string) string {
	item := cayonlib.Read(env, TPlot(), plotId)
	return item.(map[string]interface{})["plot"].(string)
}
