/*
@Author: Chad Lazarra 
@Date: 3-Nov-2026
@Desc: Wrapper Class for Error Response
@History: [1] Created - 3-Nov-2026
*/
public class ErrorResponse {

    public Integer statusCode;
    public String message;

    public ErrorResponse(Integer statusCode, String message) {
        this.statusCode = statusCode;
        this.message = message;
    }
}