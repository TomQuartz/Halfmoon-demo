package cayonlib

import (
	"log"
	"os"
	
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
)

var sess = session.Must(session.NewSession(&aws.Config{
	Region:   aws.String("ap-southeast-1"),
	Endpoint: aws.String("http://10.96.128.129:8000"),
}))

var DBClient = dynamodb.New(sess)

var T = int64(60)

var TYPE = "WRITELOG" // options: READLOG, WRITELOG

func init() {
	switch os.Getenv("LoggingMode") {
	case "read":
		TYPE = "READLOG"
	case "write":
		TYPE = "WRITELOG"
	case "none":
		TYPE = "NONE"
	case "":
		TYPE = "WRITELOG"
		log.Println("[INFO] LoggingMode not set, defaulting to WRITELOG")
	default:
		log.Fatalf("[FATAL] invalid LoggingMode: %s", os.Getenv("LoggingMode"))
	}
	log.Printf("[INFO] log mode: %s", TYPE)
}

func CHECK(err error) {
	if err != nil {
		panic(err)
	}
}

var kTablePrefix = os.Getenv("TABLE_PREFIX")
