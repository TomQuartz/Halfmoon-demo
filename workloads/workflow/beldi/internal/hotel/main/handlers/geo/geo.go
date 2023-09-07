package main

import (
	// "github.com/aws/aws-lambda-go/lambda"
	"os"
	"strconv"

	"github.com/eniac/Beldi/internal/hotel/main/geo"
	"github.com/eniac/Beldi/pkg/beldilib"
	"github.com/mitchellh/mapstructure"

	"cs.utexas.edu/zjia/faas"
)

var kNearest = 6

func init() {
	if kn, err := strconv.Atoi(os.Getenv("K_NEAREST")); err == nil {
		kNearest = kn
	} else {
		panic("invalid K_NEAREST")
	}
}

func Handler(env *beldilib.Env) interface{} {
	req := geo.Request{}
	err := mapstructure.Decode(env.Input, &req)
	beldilib.CHECK(err)
	return geo.Nearby(env, req, kNearest)
}

func main() {
	// lambda.Start(beldilib.Wrapper(Handler))
	faas.Serve(beldilib.CreateFuncHandlerFactory(Handler))
}
