$(function () {
  $('.read-more').on('click', (element) => {
    $(element.target)
      .parents('.post-content')
      .toggleClass('closed');
  })
});
