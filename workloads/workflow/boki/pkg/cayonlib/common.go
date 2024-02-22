package cayonlib

import (
	"context"
	"os"

	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/redis/go-redis/v9"
)

var sess = session.Must(session.NewSessionWithOptions(session.Options{
	SharedConfigState: session.SharedConfigEnable,
}))

var DBClient = dynamodb.New(sess)

var ctx = context.Background()

var RDBClient = redis.NewClient(&redis.Options{
	Addr:     "redis-16528.c302.asia-northeast1-1.gce.cloud.redislabs.com:16528",
	Password: "mRbG4pfnRbwIKaHgIFi08kVTgNxBT831", // no password set
	DB:       0,                                  // use default DB
})

var T = int64(60)

var TYPE = "BELDI"

func CHECK(err error) {
	if err != nil {
		panic(err)
	}
}

var kTablePrefix = os.Getenv("TABLE_PREFIX")
