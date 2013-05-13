using System;

namespace Penelope.Web.Models
{
    public class HomePage
    {
        public virtual Guid Id { get; set; }
        public virtual string Title { get; set; }
        public virtual string Text { get; set; }
    }
}