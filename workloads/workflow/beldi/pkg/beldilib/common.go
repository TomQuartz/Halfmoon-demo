package beldilib

import (
	"os"
	"strconv"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
)

var sess = session.Must(session.NewSession(&aws.Config{
	Region:   aws.String("ap-southeast-1"),
	Endpoint: aws.String("http://10.96.128.129:8000"),
}))

var DBClient = dynamodb.New(sess)

var DLOGSIZE = "1000"

func GLOGSIZE() int {
	r, _ := strconv.Atoi(DLOGSIZE)
	return r
}

// var T = int64(60)
var T = int64(30)

var TYPE = "BELDI"

func CHECK(err error) {
	if err != nil {
		panic(err)
	}
}

var kTablePrefix = os.Getenv("TABLE_PREFIX")
