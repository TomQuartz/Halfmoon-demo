package order

import (
	"github.com/eniac/Beldi/internal/hotel/main/data"
	"github.com/eniac/Beldi/pkg/cayonlib"
	"github.com/lithammer/shortuuid"
)

type Order struct {
	OrderId  string
	FlightId string
	HotelId  string
	UserId   string
}

func PlaceOrder(env *cayonlib.Env, userId string, flightId string, hotelId string) {
	orderId := shortuuid.New()
	cayonlib.Write(env, data.Torder(), orderId,
		map[string]interface{}{"V": Order{
			OrderId: orderId, FlightId: flightId, HotelId: hotelId, UserId: userId,
		}})
}
